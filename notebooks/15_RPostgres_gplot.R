library("RODBC")
library("odbc")
library(RPostgres)  # 加载 RPostgres 包

con <- dbConnect(RPostgres::Postgres(),
                  host = "127.0.0.1",
                  port = 5432,
                  dbname = "mimiciii",
                  user = "postgres",
                  password = "123")
iculos = dbGetQuery(con, "select admission_age from mimiciii.icustay_detail")

# 执行查询mimiciii.finaldata
sql_query <- "SELECT * FROM mimiciii.finaldata"
# 执行查询并将结果存储在一个数据框中
data <- dbGetQuery(con, sql_query)


require("ggplot2")
qplot(iculos$admission_age,geom = "histogram", binwidth = 1, main = "所有ICU患者年龄分布")




require("ggplot2")
 
# 执行查询并将结果存储在数据框 iculos 中
iculos <- dbGetQuery(con, "select admission_age from mimiciii.icustay_detail")

# 绘制直方图
qplot(iculos$admission_age, geom = "histogram", binwidth = 1, 
    main = "所有ICU患者年龄分布", xlab = "年龄", ylab = "样本数", 
    fill = I("#9ebcda"), col = I("#FFFFFF"))
require("ggplot2")

# 执行查询并将结果存储在数据框 iculos 中
iculos <- dbGetQuery(con, "select admission_age from mimiciii.icustay_detail")

# 绘制直方图，限制横坐标范围为0到150
qplot(iculos$admission_age, geom = "histogram", binwidth = 1, 
    main = "所有ICU患者年龄分布", xlab = "年龄", ylab = "样本数", 
    fill = I("#9ebcda"), col = I("#FFFFFF"),
    xlim = c(0, 150))



iculos <- dbGetQuery(con, "select admission_age, hospital_expire_flag, COUNT(*) as death_count from mimiciii.icustay_detail GROUP BY admission_age, hospital_expire_flag")
 
# 计算死亡的总数和总的 ICU 住院人数
total_deaths <- sum(iculos$death_count[iculos$hospital_expire_flag == 1])
total_icu_stays <- sum(iculos$death_count)

# 绘制直方图，根据 hospital_expire_flag 变量进行分组，并设置填充颜色和边框颜色
p <- ggplot(iculos, aes(x=admission_age, y=..count.., fill=factor(hospital_expire_flag))) +
    geom_histogram(binwidth=1, colour="#FFFFFF") +
    annotate("text", x = 75, y = 1800, label = paste("总死亡数：", total_deaths)) +
    annotate("text", x = 75, y = 1700, label = paste("总ICU住院人数：", total_icu_stays)) +
    labs(title="ICU患者是否死亡分布", x="年龄", y="样本数") +
    xlim(c(0, 150)) + ylim(c(0, 2000))

print(p)




