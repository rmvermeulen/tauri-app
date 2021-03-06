use serde::Deserialize;

#[derive(Deserialize)]
#[serde(tag = "cmd", rename_all = "camelCase")]
pub enum Cmd {
  // your custom commands
  // multiple arguments are allowed
  // note that rename_all = "camelCase": you need to use "myCustomCommand" on JS
  SearchGlob {
    pattern: String,
    callback: String,
    error: String,
  },
  LoadResource {
    id: String,
    amount: usize,
    callback: String,
    error: String,
  },
}
