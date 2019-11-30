
import 'dart:async';

typedef Future TaskBuilder();

class ConcurrentQueue {

  int count = 0;
  TaskBuilder taskBuilder;

  Set<Future> tasks = Set();

  bool stop = false;

  Completer completer = Completer();

  ConcurrentQueue(this.count, this.taskBuilder) {
    getTask();
  }

  Future get future => completer.future;

  getTask() {

    while (tasks.length < this.count && stop == false) {
      final task = this.taskBuilder();
      if(task == null) {
        stop = true;
        return;
      }
      tasks.add(task);
      task.then((v) {
        tasks.remove(task);
        getTask();
      }, onError: (error) {
        completer.completeError(error);
        stop = true;
        return;
      });
    }

    if(tasks.length == 0 && stop == true){
      completer.complete();

    }
  }

}