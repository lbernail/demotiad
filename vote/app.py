from flask import Flask, render_template, request, make_response, g
from redis import Redis
import os
import socket
import random
import json
import consul

option_a = os.getenv('OPTION_A', "vim")
option_b = os.getenv('OPTION_B', "emacs")
consul_host = os.getenv('CONSUL_HOST', None)
hostname = socket.gethostname()

app = Flask(__name__)


def get_consul():
    if not hasattr(g, 'consul'):
        g.consul=consul.Consul(host=consul_host,port=8500)
    return g.consul


def get_redis():
    if not hasattr(g, 'redis'):
        if consul_host is not None:
            consul=get_consul()
            (index,redis_svc) = consul.catalog.service('redis')
            redis_host = redis_svc[0]["Address"]
            redis_port = redis_svc[0]["ServicePort"]
        else:
             redis_host = 'redis'
             redis_port = '6379'

        g.redis = Redis(host=redis_host, port=redis_port, db=0, socket_timeout=5)
    return g.redis


@app.route("/", methods=['POST','GET'])
def hello():
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]

    vote = None

    redis = get_redis()

    if request.method == 'POST':
        vote = request.form['vote']
        stored_vote = redis.hget('votes',voter_id)

        if stored_vote != vote:
            redis.hset('votes',voter_id,vote)
            redis.zincrby('scores',vote,1)

            if stored_vote is not None:
                # Existing vote, removing
                redis.zincrby('scores',stored_vote,-1)

    score_a = redis.zscore('scores','a')
    if score_a is None:
        score_a = 0
    score_b = redis.zscore('scores','b')
    if score_b is None:
        score_b = 0

    score_a = str(int(score_a))
    score_b = str(int(score_b))

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        score_a=score_a,
        score_b=score_b,
        hostname=hostname,
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=True, threaded=True)
