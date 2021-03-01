#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]
use anyhow::anyhow;
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;
use uuid::Uuid;

mod cmd;

fn main() {
  let cache = Arc::new(Mutex::new(HashMap::new()));
  tauri::AppBuilder::new()
    .invoke_handler(move |_webview, arg| {
      let mut cache = cache.clone();
      use cmd::Cmd::*;
      match serde_json::from_str(arg) {
        Err(e) => Err(e.to_string()),
        Ok(command) => {
          match command {
            GetItems {
              id,
              callback,
              error,
            } => {
              let fetchItems = move || {
                let results: Vec<String> = vec![];
                Ok(results)
              };
              tauri::execute_promise(_webview, fetchItems, callback, error);
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
                  let id = Uuid::new_v4();
                  match cache.lock() {
                    Ok(mut map) => {
                      map.insert(id, results);
                      Ok(id.to_string())
                    }
                    Err(e) => Err(anyhow!("PoisonError: {}", e)),
                  }
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
