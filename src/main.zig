const std = @import("std");
const c = @import("c");

pub fn main() !void {


    const instance = c.wgpuCreateInstance(null);
    defer c.wgpuInstanceRelease(instance);

    if (instance != null) {

        std.debug.print("we got an instance {}\n", .{instance.?});

    } else {

        @panic("we failed getting a instance, lets crash");
    }

}

