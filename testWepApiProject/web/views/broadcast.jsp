<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>

	<head>
		<meta charset="UTF-8">
		<title>Broadcast</title>
		<script type="text/javascript" src="<%=request.getContextPath()%>/resources/js/jquery-3.3.1.min.js"></script>
		<style>
			 #messageWindow {
			    background:LightSkyBlue;
			    height:300px;
			    overflow:auto;
			 }
			 #userWindow {
			    background: #e0fee0;
			    height:340px;
			    overflow:auto;
			 }
			 .chat_content{
			    background: white;
			    padding: 10px;
			    border-radius: 10px;
			    display: inline-block;
			    position: relative;
			    margin: 10px;
			    float: right;
			    clear: both;
			 }
			 
			 .chat_content:after{
			    content: '';
			   position: absolute;
			   right: 0;
			   top: 50%;
			   width: 0;
			   height: 0;
			   border: 20px solid transparent;
			   border-left-color: white;
			   border-right: 0;
			   border-top: 0;
			   margin-top: -3.5px;
			   margin-right: -10px;
			 }
			 
			 .other-side {
			    background: rgb(255, 255, 102);
			    float:left;
			    clear:both;
			 }
			 
			 .other-side:after{
			    content: '';
			   position: absolute;
			   left: 0;
			   top: 50%;
			   width: 0;
			   height: 0;
			   border: 20px solid transparent;
			   border-right-color: rgb(255, 255, 102);
			   border-left: 0;
			   border-top: 0;
			   margin-top: -3.5px;
			   margin-left: -10px;
			 }
			 
			 fieldset > button{
			    width:60px; 
			    height:50px; 
			    margin-top:-50px; 
			    vertical-align: middle;
			 }
		</style>
	</head>
	
	<body>
		<h1>Broadcast 란?</h1>
		<h3>한 네트워크에 속한 모든 사용자가 소통할 수 있는 1:n의 통신 방식</h3>
		<p>Ex) 라디오 방송, 지상파 TV 프로그램, 위성 방송</p>
		
		사용할 ID : <input type="text" id="chat_id" /><br>
		<button type="button" id="startBtn">채팅하기</button>
		
		<!-- 채팅창 부분 -->
		<div id="chatbox" style="display:none;">
			<fieldset style="display:inline-block; width:65%; background:lightgray;">
				<div id="messageWindow"></div><br>
				<textarea id="inputMessage" rows="4" style="width:50%; resize:none;"></textarea>
				<button type="submit" onclick="send()">보내기</button>
				<button type="button" id="endBtn">나가기</button>
			</fieldset>
			<fieldset style="display:inline-block; width:15%;">
				<div id="userWindow"></div>
			</fieldset>
		</div>
		
		<script>
			$('#startBtn').on('click', function() {
				$('#chatbox').css('display', 'block');
				$(this).css('display', 'none');
				connection();
			});
			
			$('#endBtn').on('click', function() {
				$('#chatbox').css('display', 'none');
				$('#startBtn').css('display', 'inline');
				
				webSocket.send($('#chat_id').val() + "|님이 채팅방을 퇴장하였습니다.");
				webSocket.close();
			});
			
			var $textarea = $('#messageWindow');			// 채팅창 내용 부분
			var webSocket = null;									// 채팅 서버
			var $inputMessage = $('#inputMessage');		// 내가 보낼 문자열을 담은 input 태그
			
			function connection() {
				webSocket = new WebSocket('ws://localhost:8088' + '<%=request.getContextPath()%>/broadcast');

				/*
					웹 소켓 생성 후 동작하는 웹 소켓 메소드들
					
					1. open : 웹 소켓 객체 생성 시 동작하여 서버와 연결을 해주는 메소드
					2. send : 서버에 특정 데이터를 전달하는 메소드
					3. message : 서버에서 전달하는 데이터를 받을 메소드
					4. error : 서버에서 데이터를 전달하는 도중 에러가 발생할 경우 수행되는 메소드
					5. close : 사용자가 서버와의 연결을 끊을 경우 사용하는 메소드
					
					*** 웹 소켓 객체는 생성자를 통해 선언 시 서버와의 연결을 자동으로 실행한다.
						  (open이 자동으로 실행된다.)
				*/
				
				// 웹 소켓을 통해 연결이 이루어 질 때 동작할 메소드
				webSocket.onopen = function(event) {
					
					$textarea.html("<p class='chat_content'>" + $('#chat_id').val() + "님이 입장하셨습니다.</p><br>");
					
					// 웹 소켓을 통해 만든 채팅 서버에 참여한 내용을 메시지로 전달 
					// 내가보낼 때에는 send / 서버로부터 받을 때에는 message
					
					webSocket.send($('#chat_id').val() + "|님이 입장하셨습니다.");
					
					getUserList();
				};
				
				// 서버로부터 메시지를 전달 받을 때 동작하는 메소드
				webSocket.onmessage = function(event) {
					// 동작할 부분
					onMessage(event);
					getUserList();
				}
				
				// 서버에서 에러가 발생할 경우 동작할 메소드
				webSocket.onerror = function(event) {
					onError(event);
				}
				
				// 서버와의 연결이 종료될 경우 동작하는 메소드
				webSocket.onclose = function(event) {
					//onClose(event);
					delUserList();
				}
			}
			
			// 엔터키를 누를 경우 메세지 보내기
			function enterKey() {
				if(window.event.keyCode == 13) {
					send();
				}
			}
			
			// 서버로 메시지를 전달하는 메소드
			function send() {
				if ($inputMessage.val() == "") {
					// 메시지를 입력하지 않을 경우
					alert("메시지를 입력해 주세요!");
				} else {
					// 메시지가 입력 되었을 경우
					$textarea.html($textarea.html() + "<p class='chat_content'>나 : " + $inputMessage.val().replace(/[\r\n]/gim,"<br>") + "</p><br>");
					webSocket.send($('#chat_id').val() + "|" + $inputMessage.val());
					$inputMessage.val("");
				}
				
				$textarea.scrollTop($textarea.height());
			}
			
			// 서버로부터 메시지를 받을 때 수행할 메소드
			function onMessage(event) {
				var message = event.data.split("|");
				var sender = message[0];				// 보낸 사람의 ID
				var content = message[1];				// 전달한 내용
				
				if(content == "") {
					// 전달 받은 글이 없거나, 전달한 사람이 내가 연결하려는 상대방이 아닐 경우
					// 아무 내용도 실행하지 않겠다.
				} else {
					$textarea.html($textarea.html() + "<p class='chat_content other-side'>" + sender + " : " + content.replace(/[\r\n]/gim,"<br>") + "</p><br>");
					
					$textarea.scrollTop($textarea.height());
				}
			}
			
			function onError(event) {
				alert(event.data);
			}
			
			function onClose(event) {
				alert(event);
			}
			
			// 새로운 사용자가 접속할 경우 사용자 리스트에 추가하기 위한 서버 비동기 통신
			function getUserList() {
				$.ajax({
					url : "/test/bcUserList.do",
					data : {
						chat_id : $('#chat_id').val()
					},
					type : "post",
					success : function(data) {
						$userList = $('#userWindow');
						$userList.empty();
						
						console.log("test:" + data);
						
						for (var idx in data) {
							var $p = $('<p>');
							
							$p.text(data[idx]);
							$userList.append($p);
						}
					}, error : function(data) {
						console.log("실패");
					}
				});
			}
			
			// 새로운 사용자가 접속을 종료할 경우 사용자 리스트에 제거하기 위한 서버 비동기 통신
			function delUserList() {
				$.ajax({
					url : "/test/bcDelUser.do",
					data : {
						chat_id : $('#chat_id').val()
					},
					type : "post",
					success : function(data) {
						$userList = $('#userWindow');
						$userList.empty();
						
						console.log(data);
						
						for (var idx in data) {
							var $p = $('<p>');
							
							$p.text(data[idx]);
							$userList.append($p);
						}
					}, error : function(data) {
						console.log("실패");
					}
				});
			}
		</script>
	</body>
	
</html>