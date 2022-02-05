# How to start the demo app

This example shows how to build a voice/text AI receptionist on top of Dasha. If you need any help, join us in our [Developer Community](https://discord.gg/R8mDP2JGmv).

1. Install the DashaCLI :
```sh
npm i @dasha.ai/cli
```
2. Create or log into your account using the Dasha CLI tool:.
```sh
npx dasha account login
```
3. Run one of the following:
    * To start outbound call run
    ```sh
    npm start <phone_number>
    ```
     (phone number in international format without `+`, for instance `12223334455`).
    * To start text chat run
    ```sh
    npm start chat
    ```
