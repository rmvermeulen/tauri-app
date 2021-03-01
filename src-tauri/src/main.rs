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

#[derive(serde::Serialize)]
struct ResourceResponse {
  items: Vec<String>,
  done: bool,
}

fn main() {
  let cache: HashMap<Uuid, Vec<String>> = HashMap::new();
  let cache = Arc::new(Mutex::new(cache));
  tauri::AppBuilder::new()
    .invoke_handler(move |_webview, arg| {
      let cache = cache.clone();
      use cmd::Cmd::*;
      match serde_json::from_str(arg) {
        Err(e) => Err(e.to_string()),
        Ok(command) => {
          match command {
            GetResourceItems {
              id,
              amount,
              callback,
              error,
            } => {
              println!("GetResourceItems {}", id);
              let uuid: Uuid = Uuid::parse_str(&id).unwrap();
              let fetch_items = move || {
                let mut map = cache.lock().unwrap();
                let items: Vec<String> = match map.get(&uuid) {
                  Some(data) => data.to_vec(),
                  None => vec![]
                };
                if items.len() > amount {
                  let (items, remainder) = items.split_at(5);
                  map.insert(uuid, remainder.to_vec());
                  Ok(ResourceResponse {
                    done: false,
                    items: items.to_vec(),
                  })
                } else {
                  map.remove(&uuid);
                  Ok(ResourceResponse { done: true, items })
                }
              };
              tauri::execute_promise(_webview, fetch_items, callback, error);
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
