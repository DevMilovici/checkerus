## Setup task

In [uploader/buffer](./checkerus/uploader/buffer/) directory must exist an **empty** folder for each worker node having the name with the template **[worker_node_ip]-[worker_node_port]**:

```
uploader
└───buffer
    ├───10.13.0.10-22
    ├───10.13.0.11-22
    └───10.13.0.12-22
```

In [uploader/checkers](./checkerus/uploader/checkers/) directory, for every task must be a directory with the task name each having a subdirectory named **active** containing a .zip file representing the checker script

```
uploader
└───buffer
    ├───task1
    |   └──active
    |      └───checker.zip
    └───task2
        └──active
           └───checker.zip
```
