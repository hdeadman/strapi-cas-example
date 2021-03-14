const puppeteer = require('puppeteer');
const assert = require('assert');

before (async function () {
    global.username = '';
    global.password = '';
  });

(async () => {
    for (var i = 0; i < process.argv.length; i++) {
        var arg = process.argv[i];
        if (arg.includes('username')) {
            global.username = arg.split("=")[1];
        }
        if (arg.includes('password')) {
            global.password = arg.split("=")[1];
        }
    }

    const browser = await puppeteer.launch({
        ignoreHTTPSErrors: true,
        headless: true
    });
    const page = await browser.newPage();

    await page.goto("https://localhost:8443/cas/login");
    page.waitForNavigation()
    await page.type('#username', global.username)
    await page.type('#password', global.password)
    await page.keyboard.press('Enter');
    
    await page.waitForNavigation();
    
    const title = await page.title();
    console.log(title)
    assert(title === "CAS - Central Authentication Service")

    const header = await page.$eval('#content div h2', el => el.innerText)
    console.log(header)
    assert(header === "Log In Successful")
    
    await page.goto("http://localhost:1337/connect/cas", {waitUntil: 'networkidle2'});
    let element = await page.$('body pre');
    let jwt = await page.evaluate(element => element.textContent.trim(), element);
    console.log(jwt);
    assert(jwt.includes("jwt"));
    await page.screenshot({path: 'jwt-token.png'});
    await browser.close();
})();
