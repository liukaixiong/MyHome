@echo off
cd h5dm-barley-backstage
echo %cd%
set /p branchName=�������֧����: 
echo "��ʼ������֧"
git pull
git checkout -B %branchName%  origin/develop
git push origin %branchName%
git checkout develop

echo "��֧������� ...."
pause