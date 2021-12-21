const name = "brightness_volume_changer";
const brightness = new AbortController();
const volume = new AbortController();

load();

document.querySelector("#close").onclick = (ev) => window.close();

chrome.runtime.sendNativeMessage(name, {}, (res) => {
  if (!brightness.signal.aborted) window.brightness.value = res.brightness;
  if (!volume.signal.aborted) window.volume.value = res.volume;
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
  chrome.runtime.sendNativeMessage(
    name,
    { brightness: ev.target.value },
    close
  );
};

window.volume.onchange = (ev) => {
  volume.abort();
  save();
  chrome.runtime.sendNativeMessage(name, { volume: ev.target.value });
};
