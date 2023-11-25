const std = @import("std");
const network = @import("network");
const c = @cImport({
    @cDefine("CNFG_IMPLEMENTATION", {});
    @cInclude("rawdraw_sf.h");
});

export var CNFGPenX: c_int = 0;
export var CNFGPenY: c_int = 0;
export var CNFGBGColor: u32 = 0;
export var CNFGLastColor: u32 = 0;
export var CNFGDialogColor: u32 = 0;

var mouseX: i32 = 0;
var mouseY: i32 = 0;
var draw: bool = false;

export fn HandleKey(keycode: c_int, bDown: c_int) void {
    _ = bDown;
    _ = keycode;
}

export fn HandleButton(x: c_int, y: c_int, button: c_int, bDown: c_int) void {
    _ = y;
    _ = x;

    //std.debug.print("{} {}\n", .{ button, bDown });
    if (button == 1) {
        if (bDown == 1) {
            draw = true;
        } else if (bDown == 0) {
            draw = false;
        }
    }
}

export fn HandleMotion(x: c_int, y: c_int, mask: c_int) void {
    _ = mask;
    mouseX = x;
    mouseY = y;
}
export fn HandleDestroy() void {}

fn drawSquare(canvas: []u32, width: u16, height: u16, x: i32, y: i32, radius: u16, color: u32) void {
    var yIndex: i32 = y - radius;
    while (yIndex < y + radius) : (yIndex += 1) {
        if (yIndex < 0 or yIndex >= height) {
            continue;
        }
        var xIndex: i32 = x - radius;
        while (xIndex < x + radius) : (xIndex += 1) {
            if (xIndex < 0 or xIndex >= width) {
                continue;
            }
            canvas[@as(usize, @intCast(yIndex * width + xIndex))] = color;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    _ = allocator;

    defer {
        _ = gpa.deinit();
    }

    _ = c.CNFGSetup("Canvas game", 800, 600);

    var canvas: [800 * 600]u32 = std.mem.zeroes([800 * 600]u32);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    _ = stdout;

    var frameTimer: std.time.Timer = try std.time.Timer.start();
    var frameNum: usize = 0;
    while (c.CNFGHandleInput() != 0) {
        _ = frameTimer.reset();
        c.CNFGClearFrame();

        if (draw) {
            //canvas[@as(usize, @intCast(mouseY * 800 + mouseX))] = 0x00_00_FF_FF;
            drawSquare(&canvas, 800, 600, mouseX, mouseY, 20, 0x00_00_00_FF);
        }
        _ = c.CNFGBlitImage(&canvas, 0, 0, 800, 600);
        _ = c.CNFGColor(0xFF_00_00_FF);
        c.CNFGTackPixel(@as(c_short, @intCast(mouseX)), @as(c_short, @intCast(mouseY)));

        c.CNFGSwapBuffers();
        var frameTime = frameTimer.read();
        if (frameTime < 16_666_666) {
            std.time.sleep(16_666_666 - frameTime);
        }
        frameNum += 1;
    }

    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
