const PERIOD = 3000; // msecs
const timeout = PERIOD - 500;

function contentTypeIsHTML(contentType) {
  return (contentType || "").match(/^text\/html|^application\/xhtml\+xml/)
}

class UpdatableElement extends HTMLDivElement {
  connectedCallback() {
    this.url = location.toString();
    this.inRequest = false;
    this.intervalId = setInterval(this.update.bind(this), PERIOD);
  }

  disconnectedCallback() {
    clearInterval(this.intervalId);
  }

  update() {
    if (!this.inRequest) {
      this.createXHR();
      this.inRequest = true
      this.xhr.send();
    }
  }

  requestLoaded = () => {
    const contentType = this.xhr.getResponseHeader("Content-Type")
    if (contentTypeIsHTML(contentType)) {
      if (this.xhr.status >= 200 && this.xhr.status < 300) {
        html = $(this.xhr.responseText);
        const content = html.find('#' + this.id).html()
        this.innerHTML = content;
      }
    }

    this.requestFinish();
  }

  requestFinish = () => {
    this.inRequest = false
  }

  requestError = (e) => {
    console.error('requestError', e)
    this.requestFinish()
  }

  createXHR() {
    const xhr = this.xhr = new XMLHttpRequest

    xhr.open("GET", this.url, true)
    xhr.timeout = timeout
    xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml")
    // xhr.setRequestHeader("Turbolinks-Referrer", referrer)
    // xhr.onprogress = this.requestProgressed
    xhr.onload = this.requestLoaded.bind(this)
    xhr.onerror = this.requestError
    xhr.ontimeout = this.requestError
    xhr.onabort = this.requestError
    xhr
  }
}
customElements.define('dapi-updatable', UpdatableElement, {extends: 'div'});
