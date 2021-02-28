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
            Message {
              message,
              callback,
              error,
            } => {
              println!("elm:message -> {:?}", message);
              count += 1;
              tauri::execute_promise(
                _webview,
                move || Ok(format!("received! greetings {} from rust!", count)),
                callback,
                error,
              );
            }
            GetFileList {
              path,
              callback,
              error,
            } => {
              println!("elm:getFileList -> {:?}", path);
              tauri::execute_promise(
                _webview,
                move || {
                  use glob::glob;

                  let results: Vec<String> = glob(&path)
                    .expect("Failed to read glob pattern")
                    .filter_map(|result| {
                      result
                        .ok()
                        .map(|buffer| buffer.into_os_string().into_string().ok())
                    })
                    .filter_map(|item| item)
                    .collect();

                  Ok(results)
                },
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
