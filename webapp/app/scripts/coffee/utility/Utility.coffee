define ->
	class Utility
		generateId: ( length ) ->
			text = ""
			possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    
			for i in [0..length]
				text += possible.charAt(Math.floor(Math.random() * possible.length))
			return text