const std = @import("std");
const app_info  = @import("app_info");
const glfw      = @import("zglfw");
const gui       = @import("zgui");
const opengl    = @import("zopengl");
const gl        = opengl.bindings; // Bindings shorthand.

fn glfwWindowSizeCallback( window: *glfw.Window, width: c_int, height: c_int ) callconv(.c) void {
    _ = window; // Unused parameter.
    gl.viewport( 0, 0, @intCast(width), @intCast(height) );
}

fn glDebugCallback(
    src        : c_uint,
    t          : c_uint,
    id         : c_uint,
    severity   : c_uint,
    len        : c_int,
    msg        : [*c]const u8,
    user_param : *const anyopaque
) callconv(.c) void {
    _ = user_param;
    _ = len;
    _ = t;
    _ = src;
    // TODO: Insert @breakpoint()?
    switch (severity) {
        gl.DEBUG_SEVERITY_HIGH         => std.log.err(  "({d}): {s}", .{ id, msg } ),
        gl.DEBUG_SEVERITY_MEDIUM       => std.log.err(  "({d}): {s}", .{ id, msg } ),
        gl.DEBUG_SEVERITY_LOW          => std.log.warn( "({d}): {s}", .{ id, msg } ),
        gl.DEBUG_SEVERITY_NOTIFICATION => std.log.info( "({d}): {s}", .{ id, msg } ),
        else                           => unreachable,
    }
}

const scope = enum { main };

pub fn main() !void {
    const gl_version_major: u16 = 4;
    const gl_version_minor: u16 = 3;

    const app_description = std.fmt.comptimePrint(
        "{s} v{d}.{d}.{d}",
        .{
            app_info.name,
            app_info.major,
            app_info.minor,
            app_info.patch,
        }
    );

    // Create app main logger:
    const main_logger = std.log.scoped( .main );
    main_logger.info( "Starting {s}...", .{app_description} );

    // Init GLFW:
    main_logger.info( "Initializing GLFW...", .{} );
    try glfw.init();
    defer glfw.terminate();

    // Create window + OpenGL context:
    main_logger.info( "Creating window surface...", .{} );
    glfw.windowHint( .client_api,              .opengl_api          );
    glfw.windowHint( .context_version_major,   gl_version_major     );
    glfw.windowHint( .context_version_minor,   gl_version_minor     );
    glfw.windowHint( .opengl_profile,          .opengl_core_profile );
    glfw.windowHint( .opengl_forward_compat,   true                 );
    glfw.windowHint( .client_api,              .opengl_api          );
    glfw.windowHint( .doublebuffer,            true                 );  
    const window = try glfw.Window.create( 960, 540, app_description, null );
    defer window.destroy();
    glfw.makeContextCurrent( window );
    glfw.swapInterval( 1 ); // Enable vsync.

    // Load OpenGL:
    main_logger.info( "Loading OpenGL Core Profile v{d}.{d}...", .{ gl_version_major, gl_version_minor } );
    try opengl.loadCoreProfile( glfw.getProcAddress, gl_version_major, gl_version_minor );    

    // Bind window resize callback function:
    main_logger.info( "Binding window resize callback function...", .{} );
    _ = window.setSizeCallback( glfwWindowSizeCallback ); // TODO: Second param later?

    // Allocator:
    var gpa_state = std.heap.GeneralPurposeAllocator( .{} ) {};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    // Init ImGui:
    const scale_factor = scale_factor: { // wot
        const scale = window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };
    gui.init( gpa );
    defer gui.deinit();
    gui.getStyle().scaleAllSizes( scale_factor );
    gui.backend.init( window );
    defer gui.backend.deinit();
    
    // Configure OpenGL:
    gl.clearColor( 0.1, 0.2, 0.3, 1.0 );
    gl.debugMessageCallback( glDebugCallback, null );
    gl.enable( gl.DEBUG_OUTPUT );
    gl.enable( gl.DEBUG_OUTPUT_SYNCHRONOUS );
    gl.enable( gl.DEPTH_TEST );

    // Main loop:
    var frame_counter: usize = 0;
    main_logger.info( "Starting main loop...", .{} );
    while ( !window.shouldClose() and window.getKey(.escape) != .press ) {
        //--------------------------------------------------------------------
        main_logger.debug( "Frame #{d}", .{frame_counter} );
        gl.clear( gl.DEPTH_BUFFER_BIT | gl.COLOR_BUFFER_BIT ); // Clear screen
        glfw.pollEvents();
        const fb_size = window.getFramebufferSize();
        gui.backend.newFrame( @intCast(fb_size[0]), @intCast(fb_size[1]) );
        defer gui.backend.draw();
        defer window.swapBuffers();
        defer frame_counter += 1;
        //--------------------------------------------------------------------
        gui.setNextWindowPos(  .{ .x = 150.0, .y = 300.0 } );
        gui.setNextWindowSize( .{ .w = 150.0, .h =  50.0 } );
        if ( gui.begin("My Window", .{}) ) {
            if ( gui.button( "Boop", .{ .w = 120.0 } ) ) {
                main_logger.info( "The button was booped!", .{} );
            }
        }
        gui.end();
        //--------------------------------------------------------------------
    }
    // Cleanup and shutdown:
    main_logger.info( "Shutting down...", .{} );
    // (defer statements will handle the rest)
}
