// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import { Socket, Presence } from "phoenix"

const alphabet = "abcdefghijklmnopqrstuvwxyz"

var uuid = require("uuid");
var id = uuid.v4();
let socket = new Socket("/socket", { params: { token: id } })

let presences = [];
// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
//let channel = socket.channel("topic:subtopic", {})

const messagesContainer = document.querySelector('#messages');
const userList = document.querySelector('#user-list');

document.getElementById('login-button').onclick = function c() {
  const group_id = document.querySelector('#group_id').value;
  var channel = socket.channel("room:lobby" + group_id, {})
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
  console.log('called');
  channel.push('login',
    {
      user_name: document.querySelector('#user_name').value,
      group_id: document.querySelector('#group_id').value
    }
  );
  document.querySelector('#login-room').style.display = 'none';
  document.querySelector('#chat-room').style.display = 'block';
  channel.on('login', (payload) => {
    const messageItem = document.createElement('li');
    messageItem.innerText = `${payload.body}`;
    userList.appendChild(messageItem);
  })

  const chatInput = document.querySelector('#chat-input');
  chatInput.addEventListener('keypress', (event) => {
    if (event.keyCode === 13) {
      channel.push('new_msg', { body: chatInput.value });
      chatInput.value = '';
    }

  });
  channel.on('new_msg', (payload) => {
    const messageItem = document.createElement('li');
    const body = payload.body;
    messageItem.innerText = `${body.writer}(${body.date}) : ${body.body}`;
    messagesContainer.appendChild(messageItem);
  })

  function removeAllChildNodes(parent) {
    while (parent.firstChild) {
      parent.removeChild(parent.firstChild);
    }
  }

  channel.on('presence_diff', (response) => {
    presences = Presence.syncDiff(presences, response);
    console.log("presences_diff");
    console.log(presences);
    Presence.list(presences).forEach(p => {
    console.log("p");
      console.log(p.metas);
      if(p.metas !== undefined) {
        const messageItem = document.createElement('li');
        messageItem.innerText = `${p.metas[0].user_name}`;
        userList.appendChild(messageItem);
      }
    });
  })

  channel.on('presence_state', (response) => {
    console.log("presences_state");
    removeAllChildNodes(userList);
    Presence.list(response).forEach(p => {
      console.log("p");
      console.log(p.metas);
      if (p.metas !== undefined) {
        const messageItem = document.createElement('li');
        messageItem.innerText = `${p.metas[0].user_name}`;
        userList.appendChild(messageItem);
      }
    });
  })
};

// for chat

export default socket
