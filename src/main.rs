mod app;
mod renderer;

use app::Application;

#[tokio::main]
async fn main() {
    let mut app = Application::new("Ray Marcher", 1280, 720);

    app.start().await;
}
