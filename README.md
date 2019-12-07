# 目的
腾讯的coscmd本身只支持本地同时存在一个桶的配置，每次调用coscmd config都会覆盖`~/.cos.conf`中的配置，如果需要同时向不同的桶上传文件的话还需要先进行本地`~/.cos.conf`的写操作，非常不合理。我比较倾向的是跟ssh的配置一样，一个配置文件可以同时支持多个桶的操作。

# 安装
由于需要对coscmd可执行文件进行修改，所以需要`sudo --unsafe`
```
sudo npm install -g multi-coscmd --unsafe
```


# 原理
相当于hook了coscmd本身的操作。目前对以下操作进行了hook:
* `coscmd config`: 在本地生成或更新`~/.cos.conf`文件之后会将文件内容写到包含所有桶的配置文件`~/.cos.conf.all`中。
* 其他使用`-b`指定桶的操作: 如果`~/.cos.conf.all`中存在指定桶的配置则会先将`~/.cos.conf`切换到对应的配置，然后再继续原有操作。

# 使用方式
因为只是添加了hook，所以与直接使用coscmd一样，另外添加了以下操作:
* `coscmd -a`: 输出`~/.cos.conf.all`文件内容到控制台
* `coscmd reset`: 删除所有的hook以及其他附加操作，但是`~/.cos.conf.all`文件会保留

```
// 可以连续配置多个桶
coscmd config -a SECRET_ID -s SECRET_KEY -b bucket1-beijing -r ap-beijing
coscmd config -a SECRET_ID -s SECRET_KEY -b bucket2-hongkong -r ap-hongkong

// 会打印上述两个配置
coscmd -a

// 以后就可以直接使用-b指定不同的桶进行文件操作
coscmd -b bucket1-beijing upload exampleobject exampleobject
coscmd -b bucket2-hongkong upload exampleobject exampleobject

```