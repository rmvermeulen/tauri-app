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
  // const handleError =
  //   "handleError" in ports ? ports.handleError.send : console.error;
  const handleError = ({ message }) => console.error(message);

  const rustMessage = (msg, cb) => promisified(msg).then(cb).catch(handleError);

  if ("sendMessage" in ports && "receiveMessage" in ports) {
    const { sendMessage, receiveMessage } = ports;
    sendMessage.subscribe((message) => {
      rustMessage({ cmd: "message", message }, receiveMessage.send);
    });
  } else {
    console.error("Missing Message ports");
  }

  if ("getFileList" in ports && "receiveResourceId" in ports) {
    const { getFileList, receiveResourceId } = ports;
    getFileList.subscribe((path) => {
      rustMessage({ cmd: "getFileList", path }, (uuid) => {
        receiveResourceId.send(uuid);
      });
    });
  } else {
    console.error("Missing FileList ports");
  }

  if ("getResourceItems" in ports && "receiveResourceItems" in ports) {
    const { getResourceItems, receiveResourceItems } = ports;
    getResourceItems.subscribe(({ rid, amount }) => {
      rustMessage(
        { cmd: "getResourceItems", id: rid, amount },
        ({ done, items }) => {
          receiveResourceItems.send({ rid, amount, items, done });
        }
      );
    });
  } else {
    console.error("Missing ResourceItem ports");
  }
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
