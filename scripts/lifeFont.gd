extends Area2D



func _on_body_entered(body):
	if body.name == "Player":
		if body.vida < 100:
			body.vida += 10;
			if body.vida > 100: body.vida = 100;
			body.atualizaUI();
			queue_free();
		
