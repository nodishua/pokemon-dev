set(BREAKPAD
    client/linux/crash_generation/crash_generation_client.cc
    client/linux/dump_writer_common/thread_info.cc
    client/linux/dump_writer_common/ucontext_reader.cc
    client/linux/handler/exception_handler.cc
    client/linux/handler/minidump_descriptor.cc
    client/linux/log/log.cc
    client/linux/microdump_writer/microdump_writer.cc
    client/linux/minidump_writer/linux_dumper.cc
    client/linux/minidump_writer/linux_ptrace_dumper.cc
    client/linux/minidump_writer/minidump_writer.
    client/minidump_file_writer.cc
    common/android/breakpad_getcontext.S
    common/convert_UTF.c
    common/md5.cc
    common/string_conversion.cc
    common/linux/elfutils.cc
    common/linux/file_id.cc
    common/linux/guid_creator.c
    common/linux/linux_libc_support.cc
    common/linux/memory_mapped_file.cc
    common/linux/safe_readlink.cc
    common/linux/http_upload.cc
)

include_directories(
  ..
)

add_library(breakpad STATIC
  ${BREAKPAD}
)

set_target_properties(breakpad
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

