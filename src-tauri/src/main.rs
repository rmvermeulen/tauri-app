#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]

mod cmd;

fn main() {
  let mut count = 0;
  tauri::AppBuilder::new()
    .invoke_handler(move |_webview, arg| {
      use cmd::Cmd::*;
      match serde_json::from_str(arg) {
        Err(e) => Err(e.to_string()),
        Ok(command) => {
          match command {
            DoSomething {
              message,
              callback,
              error,
            } => {
              println!("elm:doSomething -> {:?}", message);
              count += 1;
              tauri::execute_promise(
                _webview,
                move || Ok(format!("received! greetings {} from rust!", count)),
                callback,
                error,
              );
            }
          }
          Ok(())
        }
      }
    })
    .build()
    .run();
}
