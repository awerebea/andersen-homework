"""
Simple web application that takes JSON {word: "STRING", "count": NUM}
as a parameter and returns string with that "word" and emoji symbol that it's
mean NUM times
"""


from flask import Flask, render_template, request
import emoji


app = Flask(__name__)


@app.route("/<emoji_name>")
def preview(emoji_name):
    string = emoji.emojize(f":{emoji_name}:")
    return render_template("preview.html", content=string)


@app.route("/", methods=["POST", "GET"])
def emojis():
    if request.method == "POST":
        content = request.get_json(force=True)
        emoji_name = content['word']
        count = content['count']
        string = ""
        for _ in range(int(count)):
            string += f":{emoji_name}:{emoji_name}"
        return emoji.emojize(string + '\n')
    else:
        return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
