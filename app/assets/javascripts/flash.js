//= require noty

const TIMEOUT=3000;
const THEME='bootstrap-v4';

window.Flash = {
  error:    (message) => { new Noty({text: message, theme: THEME, type: 'error', timeout: TIMEOUT}).show() },
  success: (message)  => { new Noty({text: message, theme: THEME, type: 'success', timeout: TIMEOUT}).show() },
  info:    (message)  => { new Noty({text: message, theme: THEME, type: 'information', timeout: TIMEOUT}).show() },
  warning: (message)  => { new Noty({text: message, theme: THEME, type: 'warning', timeout: TIMEOUT}).show() }
}
