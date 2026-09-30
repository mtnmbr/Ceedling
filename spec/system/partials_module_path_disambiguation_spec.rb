# =========================================================================
#   Ceedling - Test-Centered Build System for C
#   ThrowTheSwitch.org
#   Copyright (c) 2010-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require 'spec_system_helper'

##
## Partials Module Path Disambiguation
## ===================================
##
## A Partial names its module with the `_MODULE` directive macros -- either bare,
## `TEST_PARTIAL_PRIVATE_MODULE(config)`, or path-qualified,
## `TEST_PARTIAL_PRIVATE_MODULE(drivers/uart, config)`. With two same-named
## modules (src/drivers/spi/config.{h,c} and src/drivers/uart/config.{h,c}):
##
##   - the path-qualified form selects exactly the module it names, for test and
##     mock Partials alike (a mock Partial's #include carries the same path);
##   - two same-named modules Partialized in one test file fail with a clear
##     message rather than silently overwriting each other's generated files.
##

PARTIALS_PATH_SPI_CONFIG_H = <<~C
  #ifndef DRIVERS_SPI_CONFIG_H
  #define DRIVERS_SPI_CONFIG_H
  int spi_config_clock_div(void);
  #endif
C

PARTIALS_PATH_SPI_CONFIG_C = <<~C
  #include "drivers/spi/config.h"
  static int clamp(int value) { return (value > 8) ? 8 : value; }
  int spi_config_clock_div(void) { return clamp(16); }
C

PARTIALS_PATH_UART_CONFIG_H = <<~C
  #ifndef DRIVERS_UART_CONFIG_H
  #define DRIVERS_UART_CONFIG_H
  int uart_config_baud(void);
  #endif
C

PARTIALS_PATH_UART_CONFIG_C = <<~C
  #include "drivers/uart/config.h"
  static int scale(int value) { return value * 100; }
  int uart_config_baud(void) { return scale(1152); }
C

PARTIALS_PATH_UART_H = <<~C
  #ifndef DRIVERS_UART_UART_H
  #define DRIVERS_UART_UART_H
  int uart_init(void);
  #endif
C

PARTIALS_PATH_UART_C = <<~C
  #include "drivers/uart/uart.h"
  #include "drivers/uart/config.h"
  int uart_init(void) { return uart_config_baud() / 100; }
C

PARTIALS_PATH_TEST_UART_CONFIG_C = <<~C
  #include "unity.h"
  #include "ceedling.h"
  #include TEST_PARTIAL_PRIVATE_MODULE(drivers/uart, config)

  void setUp(void) {}
  void tearDown(void) {}

  void test_scale(void) { TEST_ASSERT_EQUAL_INT(500, scale(5)); }
C

PARTIALS_PATH_TEST_UART_MOCK_C = <<~C
  #include "unity.h"
  #include "ceedling.h"
  #include TEST_PARTIAL_PUBLIC_MODULE(drivers/uart, uart)
  #include MOCK_PARTIAL_ALL_MODULE(drivers/uart, config)
  MOCK_PARTIAL_CONFIG(drivers/uart/config, -scale)

  void setUp(void) {}
  void tearDown(void) {}

  void test_init_uses_config(void) {
    uart_config_baud_ExpectAndReturn(9600);
    TEST_ASSERT_EQUAL_INT(96, uart_init());
  }
C

PARTIALS_PATH_TEST_BOTH_C = <<~C
  #include "unity.h"
  #include "ceedling.h"
  #include TEST_PARTIAL_PRIVATE_MODULE(drivers/uart, config)
  #include TEST_PARTIAL_PRIVATE_MODULE(drivers/spi, config)

  void setUp(void) {}
  void tearDown(void) {}

  void test_dummy(void) { TEST_ASSERT_TRUE(1); }
C

ceedling_system_tests do
  include_context "a fresh ceedling gem project", "partials_module_paths"

  def write_same_named_config_modules
    in_project do
      @c.merge_project_yml_for_test({ :project => { :use_partials => true } })
      FileUtils.mkdir_p('src/drivers/spi')
      FileUtils.mkdir_p('src/drivers/uart')
      File.write('src/drivers/spi/config.h', PARTIALS_PATH_SPI_CONFIG_H)
      File.write('src/drivers/spi/config.c', PARTIALS_PATH_SPI_CONFIG_C)
      File.write('src/drivers/uart/config.h', PARTIALS_PATH_UART_CONFIG_H)
      File.write('src/drivers/uart/config.c', PARTIALS_PATH_UART_CONFIG_C)
      File.write('src/drivers/uart/uart.h', PARTIALS_PATH_UART_H)
      File.write('src/drivers/uart/uart.c', PARTIALS_PATH_UART_C)
    end
  end

  describe "Deployed as a gem" do

    describe "a test Partial of a path-qualified module among same-named modules" do
      before do
        write_same_named_config_modules
        in_project { File.write('test/test_uart_config.c', PARTIALS_PATH_TEST_UART_CONFIG_C) }
      end

      it "partializes exactly the module its path names" do
        in_project do
          output = @c.ceedling_build_exec("test:all")
          expect(@c.last_exit_status).to eq(0)
          expect(output).to_not match(/Multiple files matched 'config/)
          expect(output).to match(/TESTED:\s+1/)
          expect(output).to match(/PASSED:\s+1/)
        end
      end
    end

    describe "a mock Partial of a path-qualified module among same-named modules" do
      before do
        write_same_named_config_modules
        in_project { File.write('test/test_uart.c', PARTIALS_PATH_TEST_UART_MOCK_C) }
      end

      it "mocks exactly the module its path names" do
        in_project do
          output = @c.ceedling_build_exec("test:all")
          expect(@c.last_exit_status).to eq(0)
          expect(output).to match(/TESTED:\s+1/)
          expect(output).to match(/PASSED:\s+1/)
        end
      end
    end

    describe "a test file Partializing two same-named modules" do
      before do
        write_same_named_config_modules
        in_project { File.write('test/test_both_configs.c', PARTIALS_PATH_TEST_BOTH_C) }
      end

      it "fails the build naming both modules" do
        in_project do
          output = @c.ceedling_build_exec("test:all")
          expect(@c.last_exit_status).to_not eq(0)
          expect(output).to match(/same-named modules drivers\/uart\/config, drivers\/spi\/config/)
        end
      end
    end

  end

end
