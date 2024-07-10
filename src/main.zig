const std = @import("std");
const net = std.net;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const loopback = try net.Ip4Address.parse("127.0.0.1", 0);
    const localhost = net.Address{ .in = loopback };
    var server = try localhost.listen(.{
        .reuse_port = true,
    });
    defer server.deinit();

    const addr = server.listen_address;
    std.debug.print("Listening on {}, access this port to end the program\n", .{addr.getPort()});

    while (true) {
        var client = try server.accept();
        defer client.stream.close();

        const message = try client.stream.reader().readAllAlloc(allocator, 1024);
        defer allocator.free(message);

        std.debug.print("{} says {s}\n", .{ client.address, message });
    }
}
