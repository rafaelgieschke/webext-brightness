const name = "brightness_volume_changer";
const brightness = new AbortController();
const volume = new AbortController();

customElements.define(
  "x-input",
  class extends HTMLElement {
    constructor() {
      super();
      const shadow = (this._shadow = this.attachShadow({ mode: "open" }));
      shadow.innerHTML = `
      <style>
      :host { display: flex; align-items: stretch; }
      input { flex-grow: 1; }
      span { align-self: center; width: 3ch; }
      </style>
      <input><span>?</span>
    `;
      this._input = shadow.querySelector("input");
      this._span = shadow.querySelector("span");
      ["type", "min", "max", "step"].forEach((v) =>
        this._input.setAttribute(v, this.getAttribute(v))
      );
      this.displayFactor = Number(this.getAttribute("display-factor")) || 1;
      this._input.addEventListener("input", () => this._update());
      this._update();
    }
    _update() {
      this._span.textContent = Math.round(
        this.valueAsNumber * this.displayFactor
      );
    }
    set value(v) {
      this._input.value = v;
      this._update();
    }
    get value() {
      return this._input.value;
    }
    set valueAsNumber(v) {
      this._input.valueAsNumber = v;
      this._update();
    }
    get valueAsNumber() {
      return this._input.valueAsNumber;
    }
    set onchange(v) {
      this._input.onchange = v;
    }
    get onchange() {
      return this._input.onchange;
    }
  }
);

load();

document.querySelector("#close").onclick = (ev) => window.close();

const port = chrome.runtime.connectNative(name);
const queue = [];
port.onMessage.addListener((msg) => (console.log(msg), queue.shift()(msg)));
const send = (msg) => (
  console.log(msg), port.postMessage(msg), new Promise((r) => queue.push(r))
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
