/* =========================================================================
    Ceedling - Test-Centered Build System for C
    ThrowTheSwitch.org
    Copyright (c) 2010-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#ifndef _CEEDLING_SUPPORT_H_
#define _CEEDLING_SUPPORT_H_

// Stringification and tokenization helper macros
#define __PARTIALS_STRINGIFY(x) __PARTIALS_STR(x)
#define __PARTIALS_STR(x) #x
#define __PARTIALS_EXPAND(x) x

// Create a unique namespaced variable name
#define PARTIAL_LOCAL_VAR(namespace, var) partial_##namespace##_##var

//
// NOTE: These macros expect symbols CMOCK_MOCK_PREFIX and CEEDLING_PARTIALS_PREFIX to be defined at compilation
//

// Token pasting (not juxtaposition) joins prefix, module and suffix, so whitespace around a
// macro argument (e.g. after the comma in `(path, module)`) never ends up in the filename
#define __PARTIALS_CAT(a, b) __PARTIALS_CAT_(a, b)
#define __PARTIALS_CAT_(a, b) a##b
#define __TEST_PARTIAL_NAME(module) __PARTIALS_CAT(__PARTIALS_CAT(CEEDLING_PARTIALS_PREFIX, module), _impl)
#define __MOCK_PARTIAL_NAME(module) __PARTIALS_CAT(CMOCK_MOCK_PREFIX, __PARTIALS_CAT(__PARTIALS_CAT(CEEDLING_PARTIALS_PREFIX, module), _interface))

// Single-module-name forms: `module` => "<prefix>module_impl.h" / "<mock prefix><prefix>module_interface.h"
#define __TEST_PARTIAL_FILE(module) __PARTIALS_STRINGIFY(__TEST_PARTIAL_NAME(module).h)
#define __MOCK_PARTIAL_FILE(module) __PARTIALS_STRINGIFY(__MOCK_PARTIAL_NAME(module).h)

// Path-qualified forms: `path, module` => "path/<prefix>module_impl.h" / "path/<mock prefix><prefix>module_interface.h"
// (same `<path>/<mock file>` shape as an ordinary mock #include with a path)
#define __TEST_PARTIAL_PATH_FILE(path, module) __PARTIALS_STRINGIFY(path/__TEST_PARTIAL_NAME(module).h)
#define __MOCK_PARTIAL_PATH_FILE(path, module) __PARTIALS_STRINGIFY(path/__MOCK_PARTIAL_NAME(module).h)

// Selects the single-name or path-qualified form by argument count
#define __PARTIALS_SELECT(_1, _2, NAME, ...) NAME
#define __TEST_PARTIAL_FILE_SELECT(...) __PARTIALS_EXPAND(__PARTIALS_SELECT(__VA_ARGS__, __TEST_PARTIAL_PATH_FILE, __TEST_PARTIAL_FILE, )(__VA_ARGS__))
#define __MOCK_PARTIAL_FILE_SELECT(...) __PARTIALS_EXPAND(__PARTIALS_SELECT(__VA_ARGS__, __MOCK_PARTIAL_PATH_FILE, __MOCK_PARTIAL_FILE, )(__VA_ARGS__))

// Partials directive macros encoding gross configuration
// Each accepts either `(module)` or `(path, module)`, e.g. `(sensor)` or `(drivers/uart, config)`
#define TEST_PARTIAL_PUBLIC_MODULE(...) __TEST_PARTIAL_FILE_SELECT(__VA_ARGS__)
#define TEST_PARTIAL_PRIVATE_MODULE(...) __TEST_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition
#define TEST_PARTIAL_ALL_MODULE(...) __TEST_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition
#define MOCK_PARTIAL_PUBLIC_MODULE(...) __MOCK_PARTIAL_FILE_SELECT(__VA_ARGS__)
#define MOCK_PARTIAL_PRIVATE_MODULE(...) __MOCK_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition
#define MOCK_PARTIAL_ALL_MODULE(...) __MOCK_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition

// Partials directive macros requiring configuration
#define TEST_PARTIAL_MODULE(...) __TEST_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition
#define MOCK_PARTIAL_MODULE(...) __MOCK_PARTIAL_FILE_SELECT(__VA_ARGS__) // Deduplicate macro definition

// Partials configuration macros
// The parameter construction ensures at least two arguments
#define TEST_PARTIAL_CONFIG(module, func1, ...)
#define MOCK_PARTIAL_CONFIG(module, func1, ...)

#endif /* _CEEDLING_SUPPORT_H_ */
