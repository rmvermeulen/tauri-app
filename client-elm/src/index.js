import "./main.css";
import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";
import { promisified } from "tauri/api/tauri";

// then call it:
const app = Elm.Main.init({
  node: document.getElementById("root"),
});
if ("ports" in app) {
  const { ports } = app;
  const handleError =
    "handleError" in ports ? ports.handleError.send : console.error;
  const rustMessage = (msg, cb) => promisified(msg).then(cb).catch(handleError);

  if ("sendMessage" in ports && "receiveMessage" in ports) {
    const { sendMessage, receiveMessage } = ports;
    sendMessage.subscribe((message) => {
      console.log("SENDING", message);
      rustMessage({ cmd: "doSomething", message }, receiveMessage.send);
    });
  }
  if ("getFileList" in ports && "receiveFileList" in ports) {
    const { getFileList, receiveFileList } = ports;
    getFileList.subscribe((path) =>
      rustMessage({ cmd: "getFileList", path }, receiveFileList.send)
    );
  }
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
