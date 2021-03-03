"""Simple web application that takes JSON {word: "STRING", "count": NUM}
as a parameter and returns string with that "word" and emoji symbol that it's
mean NUM times
"""


from flask import Flask, render_template, request
from random import randint
import emoji


app = Flask(__name__)


@app.route("/<emoji_name>")
def preview(emoji_name):
    """Generate a page with preview of an emoji based on its name"""
    string = emoji.emojize(f":{emoji_name}:")
    return render_template("preview.html", content=string)


@app.route("/", methods=["POST", "GET"])
def emojis():
    """Generate a decorated string based on a JSON object, or return a static
    page, depending on the method header in the request.
    """
    emo_arr = ["elephant", "turtle", "mouse", "thumbs_up", "cat",
               "dog", "alien", "panda", "snake", "crocodile"]
    if request.method == "POST":
        content = request.get_json(force=True)
        emo_nm = emo_arr[randint(0, len(emo_arr) - 1)]
        word = content['word']
        count = content['count']
        string = ""
        for _ in range(int(count)):
            string += f":{emo_nm}:{word}"
        return emoji.emojize(string + '\n')
    return render_template("index.html")


if __name__ == "__main__":
    app.run(ssl_context=('ssl_cert', 'ssl_key'), debug=True)
