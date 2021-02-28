import "./main.css";
import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";
import { invoke, promisified } from "tauri/api/tauri";

// then call it:
const app = Elm.Main.init({
  node: document.getElementById("root"),
});
if ("ports" in app) {
  const { ports } = app;
  if ("sendMessage" in ports) {
    ports.sendMessage.subscribe((message) => {
      console.log("SENDING", message);
      promisified({ cmd: "doSomething", message })
        .then((response) => {
          console.log("RECEIVING", response);
          if ("receiveMessage" in ports) {
            ports.receiveMessage.send(response);
          }
        })
        .catch((error) => console.error({ error }));
    });
  }
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
