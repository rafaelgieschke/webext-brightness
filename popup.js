const name = "brightness_volume_changer";
const brightness = new AbortController();
const volume = new AbortController();

load();

document.querySelector("#close").onclick = (ev) => window.close();

const port = chrome.runtime.connectNative(name);
const queue = [];
port.onMessage.addListener((msg) => queue.shift()(msg));
const send = (msg) => (
  port.postMessage(msg), new Promise((r) => queue.push(r))
);

send({}).then((res) => {
  if (!brightness.signal.aborted) window.brightness.value = res.brightness;
  if (!volume.signal.aborted) window.volume.value = res.volume;
  document.body.style.backgroundColor = "";
  save();
});

function load() {
  const { brightness, volume } = JSON.parse(localStorage.settings ?? "{}");
  window.brightness.value = brightness;
  window.volume.value = volume;
}

function save() {
  localStorage.settings = JSON.stringify({
    brightness: window.brightness.value,
    volume: window.volume.value,
  });
}

window.brightness.onchange = (ev) => {
  brightness.abort();
  save();
  send({ brightness: ev.target.value });
};

window.volume.onchange = (ev) => {
  volume.abort();
  save();
  send({ volume: ev.target.value });
};
