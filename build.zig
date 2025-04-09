const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const snappy_version = std.SemanticVersion.parse("1.2.2") catch unreachable;

    const module = b.addModule("snappy", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    module.addCSourceFiles(.{
        .root = b.path("."),
        .files = &[_][]const u8{
            "snappy-sinksource.cc",
            "snappy-stubs-internal.cc",
            "snappy.cc",
            "snappy-c.cc",
        },
        .flags = &[_][]const u8{
            "-std=c++11",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-Wno-sign-compare",
        },
    });
    const snappy_stubs_public_h = b.addConfigHeader(.{
        .style = .{ .cmake = b.path("snappy-stubs-public.h.in") },
    }, .{
        .HAVE_SYS_UIO_H_01 = target.result.os.tag != .windows,
        .PROJECT_VERSION_MAJOR = @as(i64, @intCast(snappy_version.major)),
        .PROJECT_VERSION_MINOR = @as(i64, @intCast(snappy_version.minor)),
        .PROJECT_VERSION_PATCH = @as(i64, @intCast(snappy_version.patch)),
    });

    module.addIncludePath(b.path("."));
    module.addConfigHeader(snappy_stubs_public_h);

    const test_snappy = b.addTest(.{
        .name = "snappy",
        .root_module = module,
        .filters = &[_][]const u8{},
    });

    const run_test_snappy = b.addRunArtifact(test_snappy);
    const tls_run_test_snappy = b.step("test", "Run the snappy test");
    tls_run_test_snappy.dependOn(&run_test_snappy.step);
}
