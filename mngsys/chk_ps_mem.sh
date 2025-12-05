for i in `seq 1 8640`
do
     ## ps auxwww | head
     ## $4 %MEM check
     ## 5 percent
     ## $0 all result of ps auxwww
     ## sleep 10
     ps auxwww | awk -v date="`date "+%Y-%m-%d_%H:%M:%S"`" '$4 > 5 {print date" "$0}' >> psauxwww_mem.out
     sleep 10
done
