const std = @import("std");

pub fn writeSavefile(io: std.Io, content: []const u8) !void {
    // Get cwd
    const cwd: std.Io.Dir = std.Io.Dir.cwd();

    // Try to make a new directory - if it exists, do nothing
    cwd.createDir(io, "savefiles", .default_dir) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    // Open directory
    var output_dir: std.Io.Dir = try cwd.openDir(io, "savefiles", .{});
    defer output_dir.close(io);

    // Open/create file
    const file: std.Io.File = try output_dir.createFile(io, "savefile.txt", .{});
    defer file.close(io);

    // Write to file
    var file_writer = file.writer(io, &.{});
    const writer = &file_writer.interface;

    _ = try writer.write(content);
}

pub fn readSavefile(io: std.Io, content: []u8) ![]u8 {
    // Get cwd
    const cwd = std.Io.Dir.cwd();

    // Open directory
    var output_dir = try cwd.openDir(io, "savefiles", .{});
    defer output_dir.close(io);

    // Open file
    const file = try output_dir.openFile(io, "savefile.txt", .{});
    defer file.close(io);

    // Read
    var file_reader = file.reader(io, &.{});
    const reader = &file_reader.interface;

    const bytes_read = try std.Io.Reader.readSliceShort(reader, content);

    return content[0..bytes_read];
}
