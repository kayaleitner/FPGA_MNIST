/**
 * A collection of useful debugging macros from the book "Learn C the hard way"
 * by Zed Shaw. To remove debugging code simply pass the NDEBUG preprocessor
 * macro
 */
#ifndef DBG_H
#define DBG_H

#include <errno.h>
#include <stdio.h>
#include <string.h>

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS 1
#endif

#ifdef NDEBUG   // If no debugging is enabled, remove all debugging statements
#define debug(msg, ...)
#else
/**
 * \brief Prints a debug message. Suppress it by defining the NDEBUG preprocess
 * constant \param msg The message that should be printed, including optional
 * parameters
 */
#define debug(msg, ...)                                                                            \
    fprintf(stderr, "[DEBUG] %s:%d: " msg "\n", __FILE__, __LINE__, ##__VA_ARGS__)
#endif

/**
 * \brief Returns the compile time name of the passed variable as string
 * \param Variable The variable
 */
#define GET_VARIABLE_NAME(Variable) #Variable

#ifdef _MSC_VER   // Work around for Windows
#define clean_errno() (errno == 0 ? "None" : "strerror() not available")
#else
#define clean_errno() (errno == 0 ? "None" : strerror(errno))
#endif   // _MSC_VER


#define log_err(M, ...)                                                                            \
    fprintf(stderr, "[ERROR] (%s:%d: errno: %s) " M "\n", __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)
#define log_warn(M, ...)                                                                           \
    fprintf(stderr, "[WARN] (%s:%d: errno: %s) " M "\n", __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)
#define log_info(M, ...)                                                                           \
    fprintf(stderr, "[INFO] (%s:%d) " M "\n", __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * \brief Check if a condition holds and goto an error routine if not
 * \param A The condition that should be checked
 * \param M The message that should be printed in case of an error
 */
#define CHECK(A, M, ...)                                                                           \
    do {                                                                                           \
        if (!(A)) {                                                                                \
            log_err(M, ##__VA_ARGS__);                                                             \
            errno = 0;                                                                             \
            goto error;                                                                            \
        }                                                                                          \
    } while (0);

/**
 * \brief Check if a variable is not null. If it is null, an error message is
 * printed and the execution jumps to an error routine \note Requires goto label
 * with name "error" \param var The variable that should be checked for null
 * value
 */
#define CHECK_NOT_NULL(var) CHECK((var) != NULL, "%s must not be null", GET_VARIABLE_NAME(var))

/**
 * \brief Checks if the condition is fulfilled and sets a variable to value.
 * Then an error message is printed and the program jumps to an error label.
 * \note Requires "goto" label with name "error"
 * \param A the condition that should be checked
 * \param var The variable that should be assigned, e.g. a return value
 * \param val The value that should be assigned to the variable
 * \param M A message that should be printed
 */
#define CHECK_AND_SET(A, var, val, M, ...)                                                         \
    do {                                                                                           \
        if (!(A)) {                                                                                \
            var = val;                                                                             \
            log_err(M, ##__VA_ARGS__);                                                             \
            errno = 0;                                                                             \
            goto error;                                                                            \
        }                                                                                          \
    } while (0);

/**
 * \brief Prints an error message and jumps to an error label, if the program
 * passes this point (use it to mark forbidden branches of code execution).
 * \param M A optional message that, should be printed
 */
#define SENTINEL(M, ...)                                                                           \
    {                                                                                              \
        log_err(M, ##__VA_ARGS__);                                                                 \
        errno = 0;                                                                                 \
        goto error;                                                                                \
    }

/**
 * @brief Check if a condition holds and goto an error routine if not
 * @note Same as "CHECK" but with the difference, that the message is only
 * printed in debug mode \param A The condition that should be checked \param M
 * The message that should be printed
 */
#define CHECK_DEBUG(A, M, ...)                                                                     \
    do {                                                                                           \
        if (!(A)) {                                                                                \
            debug(M, ##__VA_ARGS__);                                                               \
            errno = 0;                                                                             \
            goto error;                                                                            \
        }                                                                                          \
    } while (0);

#endif
