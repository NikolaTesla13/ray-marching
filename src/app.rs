use winit::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::Window,
};

use crate::rendering::renderer::Renderer;

pub struct Application {
    pub name: &'static str,
    pub width: u32,
    pub height: u32,
}

impl Application {
    pub fn new(title: &'static str, width: u32, height: u32) -> Self {
        Application {
            name: title,
            width: width,
            height: height,
        }
    }

    pub async fn start(&mut self) {
        let event_loop = EventLoop::new();

        let window = winit::window::Window::new(&event_loop).unwrap();
        window.set_title(self.name);
        window.set_inner_size(winit::dpi::LogicalSize::new(self.width, self.height));

        let renderer = Renderer::new(&window).await;

        env_logger::init();
        pollster::block_on(self.run(event_loop, window, renderer));
    }

    async fn run(&self, event_loop: EventLoop<()>, window: Window, _renderer: Renderer) {
        event_loop.run(move |event, _, control_flow| {
            *control_flow = ControlFlow::Wait;

            match event {
                Event::WindowEvent {
                    event: WindowEvent::Resized(size),
                    ..
                } => {
                    _renderer.resize(size);
                    window.request_redraw();
                }
                Event::RedrawRequested(_) => {
                    _renderer.render();
                }
                Event::WindowEvent {
                    event: WindowEvent::CloseRequested,
                    ..
                } => *control_flow = ControlFlow::Exit,
                _ => {}
            }
        });
    }
}
