extends Node

signal logged_in
signal logged_out

## The server host
const SERVER_PATH := "https://quiver.dev"

## The URL for registering guest accounts
const GUEST_REGISTRATION_PATH := "/player-accounts/register/"

var auth_token := ProjectSettings.get_setting("quiver/general/auth_token", "")
var config = ConfigFile.new()
var config_file_path := ProjectSettings.get_setting("quiver/player_accounts/config_file_path", "user://account.cfg")
var player_token := ""

@onready var http_request := $HTTPRequest


func _ready() -> void:
	var err = config.load(config_file_path)
	if err == OK:
		player_token = config.get_value("general", "player_token")
		var hash = str(player_token).sha256_text()
		if hash != config.get_value("general", "hash"):
			DirAccess.remove_absolute(config_file_path)
			player_token = ""


## Registers a guest account for the current player and logs them in.
## The user remains logged in indefinitely until they are logged out.
## Guest accounts can't be logged into again either after logout or from another device.
## The benefit of guest accounts is that they don't require any input from the user.
##
## Returns true if the player was successfully registered as a guest and logged in.
func register_guest() -> bool:
	if not auth_token:
		printerr("[Quiver Player Accounts] Auth token is not set. Please set this in Project Setting->Quiver->General.")
		return false
	if player_token:
		printerr("[Quiver Player Accounts] The player is already logged in. Please log out the current player before creating a new account.")

	var error = http_request.request(
		SERVER_PATH + GUEST_REGISTRATION_PATH,
		["Authorization: Token " + auth_token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"guest": true})
	)
	if error != OK:
		printerr("[Quiver Player Accounts] There was an error registering as a guest.")
	else:
		var response = await http_request.request_completed
		var response_code = response[1]
		if response_code >= 200 and response_code <= 299:
			var body = response[3]
			var parsed_data = JSON.parse_string(body.get_string_from_utf8())
			if parsed_data is Dictionary and "token" in parsed_data:
				player_token = parsed_data["token"]
				_save_config()
				logged_in.emit()
				return true
		else:
			printerr("[Quiver Player Accounts] There was an error registering as a guest (HTTP error code %d)" % response_code)
	return false


## Logs the current player out.
func log_out():
	player_token = ""
	DirAccess.remove_absolute(config_file_path)
	logged_out.emit()


## Returns whether the current player is logged into a player account.
func is_logged_in() -> bool:
	return player_token != ""


func _save_config() -> void:
	config.set_value("general", "player_token", player_token)
	# We calculate the hash to prevent the player from arbitrarily changing the player token
	# in the file. This is easy to bypass, but provides some basic protection.
	var hash = player_token.sha256_text()
	config.set_value("general", "hash", hash)
	config.save(config_file_path)
