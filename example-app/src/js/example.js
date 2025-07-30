import { GoogleTagManager } from '@capgo/capactior-gtm';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    GoogleTagManager.echo({ value: inputValue })
}
