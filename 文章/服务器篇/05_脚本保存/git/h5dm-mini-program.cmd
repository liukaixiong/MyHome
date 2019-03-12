@echo off
cd h5dm-mini-program
echo %cd%
set /p branchName=请输入分支名称: 
echo "开始创建分支"
git pull
git checkout -B %branchName%  origin/develop
git push origin %branchName%
git checkout develop

echo "分支创建完毕 ...."
pause