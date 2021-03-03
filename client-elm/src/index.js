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

  if ("searchGlob" in ports && "receiveResourceId" in ports) {
    const { searchGlob, receiveResourceId } = ports;
    searchGlob.subscribe((pattern) => {
      rustMessage({ cmd: "searchGlob", pattern }, (uuid) => {
        receiveResourceId.send(uuid);
      });
    });
  } else {
    console.error("Missing searchGlob/receiveResourceId ports");
  }

  if ("loadResource" in ports) {
    const { loadResource } = ports;
    loadResource.subscribe(({ rid, amount, resPort }) => {
      if (resPort in ports) {
        rustMessage(
          { cmd: "loadResource", id: rid, amount },
          ({ done, items }) => {
            ports[resPort].send({ rid, amount, items, done });
          }
        );
      } else {
        console.error(`Missing resPort [${resPort}]`);
      }
    });
  } else {
    console.error("Missing loadResource port");
  }
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
