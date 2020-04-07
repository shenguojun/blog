## 构建前提
* 安装hugo或更新hugo
```shell
brew install hugo
```
or 
```
brew upgrade hugo
```
## 编写和生成博客
* 执行`hugo new content/post/xxx.md`生成文章
* 在xxx.md编辑文章内容
* 执行`hugo server -D`查看预览
* 执行`./deploy.sh`生成博客并将新生成文件提交到远程github
* 执行`./updateAndDeploy.sh`更新submodule并重新文章，然后提交到远程github
* 如有图片复制到`static/image`文件夹中，执行`./deploy.sh`，  
并在文章中使用`![xxx.png](https://shenguojun.github.io/image/xxx.png)`引用图片
