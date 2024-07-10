const signal = @cImport({
    @cInclude("signal.h");
});

const std = @import("std");
const net = std.net;

var server: ?net.Server = null;

fn intHandler(_: c_int) callconv(.C) void {
    std.debug.print("Exiting gracefully\n", .{});
    if (server) |s| {
        net.Stream.close(s.stream);
    }
    std.process.exit(0);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const loopback = try net.Ip4Address.parse("127.0.0.1", 0);
    const localhost = net.Address{ .in = loopback };
    var svr = try localhost.listen(.{
        .reuse_port = true,
    });
    server = svr;
    defer svr.deinit();

    _ = signal.signal(signal.SIGINT, intHandler);

    const addr = svr.listen_address;
    std.debug.print("Listening on {}, access this port to end the program\n", .{addr.getPort()});

    while (true) {
        var client = try svr.accept();
        defer client.stream.close();

        const message = try client.stream.reader().readAllAlloc(allocator, 1024);
        defer allocator.free(message);

        std.debug.print("{} says {s}\n", .{ client.address, message });
    }
}
