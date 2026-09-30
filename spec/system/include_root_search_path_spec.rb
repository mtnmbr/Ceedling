# =========================================================================
#   Ceedling - Test-Centered Build System for C
#   ThrowTheSwitch.org
#   Copyright (c) 2010-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require 'spec_system_helper'

##
## Include Root Search Path
## ========================
##
## A project may put only the root of its header tree on the include search path and
## spell every #include with its path below that root (`#include "drivers/uart/uart.h"`
## with `-I lib`), exactly as the compiler resolves it. Ceedling must then:
##
##   - accept those #includes (and mocks of them) without every header directory being
##     a search path of its own;
##   - generate mocks that #include their real header by that same path;
##   - render those #includes into generated test runners as written.
##

INCLUDE_ROOT_TYPES_H = <<~C
  #ifndef DRIVERS_COMMON_TYPES_H
  #define DRIVERS_COMMON_TYPES_H
  typedef int baud_t;
  #endif
C

INCLUDE_ROOT_CLOCK_H = <<~C
  #ifndef DRIVERS_COMMON_CLOCK_H
  #define DRIVERS_COMMON_CLOCK_H
  #include "drivers/common/types.h"
  baud_t clock_rate(void);
  #endif
C

INCLUDE_ROOT_CLOCK_C = <<~C
  #include "drivers/common/clock.h"
  baud_t clock_rate(void) { return 115200; }
C

INCLUDE_ROOT_UART_H = <<~C
  #ifndef DRIVERS_UART_UART_H
  #define DRIVERS_UART_UART_H
  #include "drivers/common/types.h"
  baud_t uart_baud(void);
  #endif
C

INCLUDE_ROOT_UART_C = <<~C
  #include "drivers/uart/uart.h"
  #include "drivers/common/clock.h"
  baud_t uart_baud(void) { return clock_rate() / 2; }
C

INCLUDE_ROOT_TEST_UART_C = <<~C
  #include "unity.h"
  #include "drivers/uart/uart.h"
  #include "drivers/common/mock_clock.h"

  void setUp(void) {}
  void tearDown(void) {}

  void test_baud_is_half_the_clock(void) {
    clock_rate_ExpectAndReturn(1000);
    TEST_ASSERT_EQUAL_INT(500, uart_baud());
  }
C

ceedling_system_tests do
  include_context "a fresh ceedling gem project", "include_root_search_path"

  describe "Deployed as a gem" do

    describe "a project with only the root of its header tree on the include search path" do
      before do
        in_project do
          @c.merge_project_yml_for_test({
            :paths => { :source => ['lib/**'], :include => ['lib'] },
            :cmock => { :mock_prefix => 'mock_' }
          })
          FileUtils.mkdir_p('lib/drivers/common')
          FileUtils.mkdir_p('lib/drivers/uart')
          File.write('lib/drivers/common/types.h', INCLUDE_ROOT_TYPES_H)
          File.write('lib/drivers/common/clock.h', INCLUDE_ROOT_CLOCK_H)
          File.write('lib/drivers/common/clock.c', INCLUDE_ROOT_CLOCK_C)
          File.write('lib/drivers/uart/uart.h', INCLUDE_ROOT_UART_H)
          File.write('lib/drivers/uart/uart.c', INCLUDE_ROOT_UART_C)
          File.write('test/test_uart.c', INCLUDE_ROOT_TEST_UART_C)
        end
      end

      it "builds and passes a test #including a header and a mock by their path below that root" do
        in_project do
          output = @c.ceedling_build_exec("test:all")
          expect(@c.last_exit_status).to eq(0)
          expect(output).to match(/TESTED:\s+1/)
          expect(output).to match(/PASSED:\s+1/)
        end
      end
    end

  end

end
