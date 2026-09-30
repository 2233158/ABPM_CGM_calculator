# --- 0. Load Required Packages ---
# Ensure packages are installed
packages <- c("shiny", "dplyr", "stringr", "DT", "shinythemes",
              "shinydashboard", "shinyjs", "tidyr", "zoo", "purrr", "plotly", "ggplot2", "openxlsx")

# Comment out install lines for typical use, uncomment if needed
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

library(shiny)
library(dplyr)
library(stringr)
library(DT)
library(shinythemes)
library(shinydashboard)
library(shinyjs)
library(tidyr)
library(zoo)
library(purrr)
library(plotly)
library(ggplot2)
library(openxlsx)

# --- 1. Built-in Example Data (Reduced to P001, P002) ---
csv_data_string <- "
MASKID,Time,SBP,DBP,HR,PP,MAP
P001,0807+0D,119,78,72,41,91.7
P001,0823+0D,125,81,74,44,95.7
P001,0847+0D,121,77,69,44,91.7
P001,0905+0D,125,79,71,46,93.7
P001,0928+0D,118,74,67,44,88.7
P001,0951+0D,116,76,73,40,89.3
P001,1011+0D,127,81,69,46,96.7
P001,1030+0D,119,77,69,42,91
P001,1052+0D,122,78,70,44,92.7
P001,1115+0D,125,79,71,46,93.7
P001,1136+0D,122,79,72,43,93
P001,1155+0D,119,75,69,44,89.7
P001,1218+0D,126,81,74,45,96
P001,1243+0D,123,76,71,47,91.7
P001,1301+0D,123,78,72,45,93
P001,1319+0D,125,79,70,46,93.7
P001,1343+0D,121,77,69,44,91.7
P001,1403+0D,125,81,74,44,95.7
P001,1427+0D,120,78,71,42,92
P001,1446+0D,120,76,71,44,90.7
P001,1505+0D,119,76,69,43,89.7
P001,1529+0D,118,75,66,43,88.7
P001,1552+0D,119,74,66,45,89
P001,1613+0D,125,79,71,46,93.7
P001,1631+0D,120,76,69,44,90.7
P001,1655+0D,117,75,67,42,89
P001,1717+0D,120,76,71,44,90.7
P001,1737+0D,117,74,67,43,87.7
P001,1800+0D,121,77,69,44,91.7
P001,1818+0D,120,78,71,42,92
P001,1838+0D,126,80,73,46,95.3
P001,1902+0D,118,75,66,43,88.7
P001,1925+0D,118,76,69,42,90
P001,1948+0D,123,79,71,44,93.7
P001,2011+0D,120,77,70,43,90.7
P001,2035+0D,118,74,66,44,88.7
P001,2053+0D,119,75,68,44,89.7
P001,2116+0D,123,78,71,45,93
P001,2139+0D,119,77,69,42,91
P001,2157+0D,120,76,69,44,90.7
P001,2224+0D,107,68,63,39,81
P001,2301+0D,110,68,60,42,82
P001,2341+0D,106,65,61,41,78.3
P001,0006+1D,106,66,60,40,79.3
P001,0038+1D,105,66,60,39,79
P001,0116+1D,105,64,59,41,77.3
P001,0157+1D,107,68,62,39,81
P001,0223+1D,103,63,58,40,76.3
P001,0256+1D,106,66,60,40,79.3
P001,0339+1D,102,64,58,38,77.3
P001,0405+1D,106,65,60,41,78.3
P001,0448+1D,104,65,59,39,78
P001,0530+1D,107,66,60,41,79.7
P001,0609+1D,108,68,62,40,81.3
P001,0637+1D,111,69,63,42,83
P001,0718+1D,111,71,65,40,84.3
P001,0741+1D,115,72,67,43,86.7
P001,0803+1D,117,74,67,43,87.7
P002,0814+0D,150,95,78,55,113.3
P002,0833+0D,144,92,75,52,109.3
P002,0856+0D,148,95,77,53,112.7
P002,0920+0D,153,97,80,56,115.7
P002,0941+0D,147,93,76,54,111
P002,1005+0D,145,91,75,54,109
P002,1029+0D,155,98,81,57,117
P002,1047+0D,146,94,77,52,111.3
P002,1107+0D,142,90,74,52,107.3
P002,1125+0D,153,96,80,57,115
P002,1147+0D,148,94,77,54,112
P002,1210+0D,157,100,83,57,119
P002,1232+0D,147,93,76,54,111
P002,1256+0D,149,95,78,54,112.7
P002,1318+0D,151,95,79,56,113.7
P002,1340+0D,141,90,74,51,107
P002,1403+0D,148,94,77,54,112
P002,1423+0D,150,95,78,55,113.3
P002,1441+0D,145,92,75,53,109.7
P002,1501+0D,150,96,79,54,114
P002,1523+0D,144,91,74,53,108.7
P002,1547+0D,152,97,80,55,115.3
P002,1610+0D,142,89,73,53,106.7
P002,1632+0D,145,92,75,53,109.7
P002,1651+0D,140,89,73,51,106
P002,1715+0D,151,95,79,56,113.7
P002,1737+0D,143,91,74,52,108.3
P002,1759+0D,148,94,77,54,112
P002,1822+0D,146,92,75,54,110
P002,1844+0D,142,90,74,52,107.3
P002,1909+0D,140,88,72,52,105.3
P002,1931+0D,145,92,75,53,109.7
P002,1953+0D,139,88,72,51,105
P002,2015+0D,142,90,74,52,107.3
P002,2038+0D,144,91,74,53,108.7
P002,2058+0D,136,86,70,50,102.7
P002,2122+0D,141,89,73,52,106.3
P002,2142+0D,137,87,71,50,103.7
P002,2218+0D,134,83,69,51,100
P002,2253+0D,129,80,66,49,96.3
P002,2334+0D,127,80,67,47,94.7
P002,0006+1D,133,83,69,50,100
P002,0048+1D,125,78,64,47,92.7
P002,0133+1D,124,77,64,47,91.7
P002,0219+1D,128,80,66,48,96
P002,0251+1D,122,76,63,46,91.3
P002,0324+1D,128,81,68,47,95.7
P002,0408+1D,126,78,65,48,94
P002,0440+1D,121,75,62,46,91
P002,0514+1D,126,79,66,47,93.7
P002,0545+1D,128,80,66,48,96
P002,0627+1D,129,81,67,48,96
P002,0709+1D,133,84,70,49,99.3
P002,0732+1D,138,86,72,52,103.3
P002,0750+1D,141,89,73,52,106.3
P002,0812+1D,144,91,74,53,108.7
P003,0755+0D,147,95,76,52,112.3
P003,0815+0D,153,97,79,56,115.7
P003,0839+0D,151,96,78,55,114.3
P003,0902+0D,154,98,80,56,116.7
P003,0920+0D,150,95,77,55,113.3
P003,0943+0D,152,97,79,55,115.3
P003,1005+0D,155,99,81,56,117.7
P003,1024+0D,148,94,76,54,111.3
P003,1047+0D,158,101,83,57,120
P003,1108+0D,152,96,78,56,114.7
P003,1132+0D,149,95,77,54,112.7
P003,1155+0D,156,99,81,57,118
P003,1215+0D,160,101,84,59,120.7
P003,1239+0D,150,95,77,55,113.3
P003,1302+0D,149,96,78,53,113.7
P003,1323+0D,153,98,80,55,116.3
P003,1345+0D,156,99,81,57,118
P003,1409+0D,147,93,75,54,111
P003,1432+0D,152,97,79,55,115.3
P003,1450+0D,148,94,76,54,111.3
P003,1514+0D,151,96,78,55,114.3
P003,1532+0D,153,97,79,56,115.7
P003,1556+0D,145,92,75,53,109.7
P003,1619+0D,154,98,80,56,116.7
P003,1639+0D,149,95,77,54,112.7
P003,1700+0D,146,93,75,53,110.7
P003,1721+0D,155,98,81,57,117
P003,1745+0D,150,95,77,55,113.3
P003,1804+0D,145,93,76,52,110.3
P003,1826+0D,152,97,79,55,115.3
P003,1846+0D,149,94,76,55,112.3
P003,1909+0D,150,96,78,54,114
P003,1933+0D,148,95,77,53,112.7
P003,1955+0D,146,93,75,53,110.7
P003,2018+0D,144,91,74,53,108.7
P003,2039+0D,149,95,77,54,112.7
P003,2102+0D,151,96,78,55,114.3
P003,2125+0D,145,92,75,53,109.7
P003,2146+0D,149,95,77,54,112.7
P003,2228+0D,149,93,75,56,111.7
P003,2259+0D,146,93,75,53,110.7
P003,2341+0D,147,94,76,53,111.7
P003,0013+1D,143,91,73,52,108.3
P003,0045+1D,148,94,76,54,112
P003,0130+1D,141,89,72,52,106.3
P003,0212+1D,145,92,74,53,109.7
P003,0256+1D,148,94,76,54,112
P003,0328+1D,144,92,74,52,109.3
P003,0411+1D,140,89,72,51,106
P003,0453+1D,143,91,73,52,108.3
P003,0528+1D,146,93,75,53,110.7
P003,0613+1D,144,92,74,52,109.3
P003,0659+1D,148,94,76,54,112
P003,0721+1D,150,95,77,55,113.3
P003,0744+1D,152,97,79,55,115.3
P003,0807+1D,153,97,79,56,115.7
P003,0830+1D,150,96,78,54,114
P003,0850+1D,148,94,76,54,111.3
P003,0915+1D,152,97,79,55,115.3
P003,0936+1D,149,95,77,54,112.7
P004,0802+0D,158,100,80,58,119.3
P004,0825+0D,170,106,86,64,127.3
P004,0849+0D,156,98,79,58,117.3
P004,0907+0D,164,103,83,61,123.3
P004,0931+0D,173,109,88,64,130.3
P004,0953+0D,160,101,81,59,120.7
P004,1017+0D,152,95,76,57,114
P004,1038+0D,168,106,85,62,126.7
P004,1059+0D,155,97,78,58,116.3
P004,1120+0D,175,110,89,65,131.7
P004,1139+0D,161,101,81,60,121
P004,1202+0D,149,92,74,57,111
P004,1224+0D,165,104,84,61,124.3
P004,1247+0D,159,100,80,59,119.7
P004,1308+0D,172,108,87,64,129.3
P004,1330+0D,153,96,77,57,115
P004,1354+0D,161,101,81,60,121
P004,1417+0D,168,106,85,62,126.7
P004,1436+0D,156,98,79,58,117.3
P004,1459+0D,147,91,73,56,109.7
P004,1520+0D,163,103,83,60,123
P004,1542+0D,170,107,86,63,128
P004,1604+0D,158,99,80,59,118.7
P004,1623+0D,150,93,75,57,112
P004,1647+0D,166,105,84,61,125.3
P004,1708+0D,159,100,80,59,119.7
P004,1731+0D,174,110,89,64,131.3
P004,1750+0D,155,97,78,58,116.3
P004,1811+0D,148,92,74,56,110.7
P004,1834+0D,162,102,82,60,122
P004,1855+0D,157,99,79,58,118.3
P004,1919+0D,169,107,86,62,127.7
P004,1943+0D,154,96,77,58,115.3
P004,2005+0D,160,101,81,59,120.7
P004,2028+0D,152,95,76,57,114
P004,2050+0D,167,105,84,62,125.7
P004,2110+0D,159,100,80,59,119.7
P004,2134+0D,151,94,75,57,113
P004,2155+0D,164,103,83,61,123.3
P004,2224+0D,165,105,82,60,125
P004,2303+0D,158,100,79,58,119.3
P004,2347+0D,169,108,85,61,128.3
P004,0029+1D,162,103,81,59,122.7
P004,0102+1D,171,109,86,62,129.7
P004,0146+1D,166,106,83,60,126
P004,0220+1D,159,101,79,58,120.3
P004,0301+1D,175,112,88,63,133
P004,0340+1D,163,104,82,59,123.7
P004,0423+1D,167,107,84,60,127
P004,0458+1D,170,109,86,61,129.3
P004,0532+1D,161,102,80,59,121.7
P004,0616+1D,168,107,84,61,127.3
P004,0655+1D,156,98,78,58,117.3
P004,0730+1D,164,104,82,60,124
P004,0758+1D,172,109,87,63,130
P004,0820+1D,160,101,80,59,120.7
P004,0841+1D,153,96,77,57,115
P005,0809+0D,118,74,75,44,88.7
P005,0828+0D,133,83,85,50,100
P005,0847+0D,121,76,77,45,91
P005,0906+0D,112,69,69,43,83.7
P005,0930+0D,128,80,81,48,96
P005,0951+0D,136,86,88,50,102.7
P005,1013+0D,119,74,75,45,89
P005,1034+0D,124,78,79,46,92.7
P005,1056+0D,131,82,84,49,98.3
P005,1118+0D,115,71,71,44,85.7
P005,1140+0D,140,90,92,50,106.7
P005,1200+0D,126,79,80,47,94.7
P005,1221+0D,117,72,73,45,87
P005,1244+0D,130,81,83,49,97.3
P005,1307+0D,123,77,78,46,92.7
P005,1328+0D,138,88,90,50,105.3
P005,1349+0D,120,75,76,45,90
P005,1413+0D,111,68,68,43,82.7
P005,1434+0D,129,81,83,48,97
P005,1457+0D,135,85,87,50,101.7
P005,1516+0D,122,76,77,46,91.3
P005,1539+0D,116,72,73,44,86.7
P005,1600+0D,132,83,85,49,99.3
P005,1624+0D,125,78,79,47,93.7
P005,1643+0D,119,74,75,45,89
P005,1706+0D,137,87,89,50,104
P005,1728+0D,123,77,78,46,92.7
P005,1750+0D,114,70,70,44,84.7
P005,1814+0D,127,80,81,47,95.7
P005,1833+0D,134,84,86,50,100.7
P005,1857+0D,121,76,77,45,91
P005,1917+0D,113,69,69,44,83.7
P005,1938+0D,130,81,83,49,97.3
P005,2000+0D,124,78,79,46,92.7
P005,2023+0D,117,72,73,45,87
P005,2045+0D,133,83,85,50,100
P005,2104+0D,126,79,80,47,94.7
P005,2128+0D,118,73,74,45,88
P005,2151+0D,129,81,83,48,97
P005,2226+0D,112,68,67,44,82.7
P005,2257+0D,105,64,63,41,77.3
P005,2339+0D,115,70,70,45,85
P005,0018+1D,100,61,60,39,74
P005,0059+1D,108,66,65,42,80
P005,0131+1D,96,58,57,38,71.3
P005,0214+1D,111,68,67,43,82.7
P005,0250+1D,103,63,62,40,76.3
P005,0333+1D,99,60,59,39,73
P005,0418+1D,106,65,64,41,78.3
P005,0451+1D,94,56,55,38,69.3
P005,0536+1D,109,67,66,42,80.3
P005,0608+1D,101,62,61,39,75
P005,0640+1D,97,59,58,38,72.3
P005,0723+1D,104,64,63,40,77.3
P005,0746+1D,110,68,67,42,82
P005,0808+1D,116,71,71,45,86
P005,0827+1D,123,77,78,46,92.7
P005,0850+1D,130,81,83,49,97.3
P005,0911+1D,120,75,76,45,90
P006,0811+0D,105,66,66,39,79
P006,0831+0D,108,67,67,41,80
P006,0854+0D,103,65,65,38,78.3
P006,0916+0D,106,66,66,40,79.3
P006,0938+0D,109,68,68,41,81
P006,0956+0D,105,65,65,40,78.3
P006,1019+0D,102,64,64,38,77.3
P006,1041+0D,107,67,67,40,80
P006,1103+0D,110,69,69,41,82.3
P006,1125+0D,104,65,65,39,78
P006,1143+0D,106,66,66,40,79.3
P006,1206+0D,108,68,68,40,81.3
P006,1229+0D,105,65,65,40,78.3
P006,1248+0D,103,64,64,39,77
P006,1312+0D,109,68,68,41,81
P006,1331+0D,107,67,67,40,80
P006,1354+0D,104,65,65,39,78
P006,1418+0D,106,66,66,40,79.3
P006,1440+0D,108,67,67,41,80
P006,1502+0D,103,64,64,39,77
P006,1521+0D,105,66,66,39,79
P006,1545+0D,107,67,67,40,80
P006,1607+0D,102,63,63,39,76
P006,1625+0D,104,65,65,39,78
P006,1648+0D,106,66,66,40,79.3
P006,1710+0D,101,63,63,38,75.7
P006,1732+0D,105,65,65,40,78.3
P006,1756+0D,107,67,67,40,80
P006,1815+0D,103,64,64,39,77
P006,1839+0D,100,62,62,38,74.7
P006,1900+0D,104,65,65,39,78
P006,1924+0D,106,66,66,40,79.3
P006,1943+0D,102,63,63,39,76
P006,2007+0D,99,61,61,38,73.7
P006,2029+0D,103,64,64,39,77
P006,2051+0D,105,65,65,40,78.3
P006,2110+0D,101,63,63,38,75.7
P006,2134+0D,104,65,65,39,78
P006,2156+0D,100,62,62,38,74.7
P006,2234+0D,93,57,58,36,70
P006,2309+0D,95,59,59,36,71
P006,2344+0D,90,55,55,35,66.7
P006,0027+1D,92,57,57,35,68.7
P006,0112+1D,88,54,54,34,65.3
P006,0157+1D,94,58,58,36,70
P006,0228+1D,90,55,55,35,66.7
P006,0311+1D,87,53,53,34,64.3
P006,0355+1D,91,56,56,35,67.7
P006,0430+1D,89,55,55,34,66.3
P006,0504+1D,86,53,53,33,64
P006,0539+1D,90,55,55,35,66.7
P006,0621+1D,92,57,57,35,68.7
P006,0656+1D,95,59,59,36,71
P006,0738+1D,97,60,60,37,72.3
P006,0800+1D,100,62,62,38,74.7
P006,0823+1D,103,64,64,39,77
P006,0845+1D,105,65,65,40,78.3
P007,0758+0D,124,80,71,44,94.7
P007,0817+0D,121,78,70,43,92
P007,0840+0D,126,81,73,45,96
P007,0903+0D,123,79,71,44,93.7
P007,0925+0D,127,82,74,45,97
P007,0948+0D,125,81,73,44,95.7
P007,1007+0D,122,79,70,43,93
P007,1029+0D,128,83,75,45,98
P007,1053+0D,124,80,71,44,94.7
P007,1112+0D,126,81,73,45,96
P007,1136+0D,129,83,75,46,98.3
P007,1158+0D,123,79,71,44,93.7
P007,1219+0D,125,81,73,44,95.7
P007,1242+0D,127,82,74,45,97
P007,1305+0D,122,78,70,44,91.3
P007,1327+0D,124,80,71,44,94.7
P007,1351+0D,126,81,73,45,96
P007,1410+0D,128,82,74,46,97.3
P007,1434+0D,123,79,71,44,93.7
P007,1456+0D,125,80,72,45,95
P007,1518+0D,127,82,74,45,97
P007,1536+0D,122,78,70,44,91.3
P007,1600+0D,124,80,71,44,94.7
P007,1621+0D,126,81,73,45,96
P007,1645+0D,121,78,70,43,92
P007,1708+0D,123,79,71,44,93.7
P007,1727+0D,125,80,72,45,95
P007,1751+0D,127,82,74,45,97
P007,1813+0D,120,77,69,43,90.7
P007,1835+0D,122,78,70,44,91.3
P007,1859+0D,124,80,71,44,94.7
P007,1918+0D,126,81,73,45,96
P007,1942+0D,121,77,69,44,90.7
P007,2001+0D,123,79,71,44,93.7
P007,2025+0D,125,80,72,45,95
P007,2047+0D,119,76,68,43,89.7
P007,2111+0D,121,78,70,43,92
P007,2130+0D,123,79,71,44,93.7
P007,2153+0D,124,80,71,44,94.7
P007,2232+0D,122,79,68,43,93
P007,2306+0D,120,77,67,43,90.7
P007,2338+0D,118,76,66,42,89.3
P007,0019+1D,123,79,69,44,93.7
P007,0051+1D,121,78,68,43,92
P007,0135+1D,119,77,67,42,90
P007,0218+1D,117,75,65,42,88
P007,0249+1D,120,77,67,43,90.7
P007,0332+1D,118,76,66,42,89.3
P007,0416+1D,116,74,64,42,87.3
P007,0450+1D,119,77,67,42,90
P007,0522+1D,121,78,68,43,92
P007,0603+1D,117,75,65,42,88
P007,0645+1D,119,77,67,42,90
P007,0717+1D,122,78,70,44,91.3
P007,0738+1D,124,80,71,44,94.7
P007,0801+1D,126,81,73,45,96
P007,0820+1D,123,79,71,44,93.7
P007,0844+1D,125,80,72,45,95
P008,0752+0D,137,86,76,51,103
P008,0812+0D,134,84,74,50,100.7
P008,0836+0D,140,88,78,52,105.3
P008,0858+0D,136,85,75,51,102
P008,0917+0D,142,90,80,52,107.3
P008,0939+0D,138,87,77,51,104
P008,1003+0D,133,83,73,50,100
P008,1024+0D,145,92,81,53,110.7
P008,1048+0D,139,88,78,51,105
P008,1107+0D,136,85,75,51,102
P008,1129+0D,141,89,79,52,106.3
P008,1153+0D,144,91,80,53,108.7
P008,1215+0D,137,86,76,51,103
P008,1234+0D,132,82,72,50,98.7
P008,1258+0D,140,88,78,52,105.3
P008,1321+0D,138,87,77,51,104
P008,1343+0D,143,90,80,53,107.7
P008,1401+0D,135,85,75,50,101.7
P008,1424+0D,139,88,78,51,105
P008,1448+0D,137,86,76,51,103
P008,1509+0D,141,89,79,52,106.3
P008,1533+0D,134,84,74,50,100.7
P008,1552+0D,138,87,77,51,104
P008,1616+0D,142,90,80,52,107.3
P008,1635+0D,136,85,75,51,102
P008,1659+0D,139,88,78,51,105
P008,1718+0D,133,83,73,50,100
P008,1741+0D,140,88,78,52,105.3
P008,1805+0D,137,86,76,51,103
P008,1827+0D,132,82,72,50,98.7
P008,1849+0D,139,88,78,51,105
P008,1913+0D,135,85,75,50,101.7
P008,1932+0D,141,89,79,52,106.3
P008,1956+0D,136,85,75,51,102
P008,2019+0D,131,82,72,49,98
P008,2041+0D,138,87,77,51,104
P008,2105+0D,134,84,74,50,100.7
P008,2126+0D,130,81,71,49,97.3
P008,2149+0D,136,85,75,51,102
P008,2219+0D,120,73,65,47,87.7
P008,2258+0D,123,75,67,48,91
P008,2337+0D,118,72,64,46,86.7
P008,0009+1D,125,77,69,48,93
P008,0047+1D,116,70,62,46,84.7
P008,0132+1D,119,72,64,47,86.7
P008,0216+1D,114,69,61,45,84
P008,0259+1D,117,71,63,46,85.7
P008,0334+1D,112,67,59,45,82
P008,0418+1D,115,70,62,45,85
P008,0453+1D,119,72,64,47,86.7
P008,0530+1D,113,68,60,45,83
P008,0615+1D,116,70,62,46,84.7
P008,0658+1D,120,73,65,47,87.7
P008,0729+1D,124,76,68,48,92
P008,0755+1D,128,79,70,49,95.3
P009,0805+0D,117,75,68,42,89
P009,0826+0D,119,76,69,43,89.7
P009,0845+0D,116,74,67,42,88.7
P009,0908+0D,120,77,70,43,91
P009,0927+0D,115,73,66,42,87.7
P009,0949+0D,118,75,68,43,89
P009,1012+0D,121,78,71,43,92
P009,1035+0D,117,75,68,42,89
P009,1054+0D,114,72,65,42,86
P009,1117+0D,119,76,69,43,89.7
P009,1136+0D,122,78,71,44,92.7
P009,1159+0D,118,75,68,43,89
P009,1218+0D,116,74,67,42,88.7
P009,1241+0D,120,77,70,43,91
P009,1300+0D,123,79,72,44,93.7
P009,1323+0D,117,75,68,42,89
P009,1345+0D,115,73,66,42,87.7
P009,1407+0D,119,76,69,43,89.7
P009,1429+0D,121,78,71,43,92
P009,1452+0D,118,75,68,43,89
P009,1511+0D,116,74,67,42,88.7
P009,1535+0D,120,77,70,43,91
P009,1558+0D,117,75,68,42,89
P009,1617+0D,115,73,66,42,87.7
P009,1639+0D,119,76,69,43,89.7
P009,1702+0D,121,78,71,43,92
P009,1725+0D,118,75,68,43,89
P009,1748+0D,116,74,67,42,88.7
P009,1807+0D,114,72,65,42,86
P009,1831+0D,118,75,68,43,89
P009,1850+0D,120,77,70,43,91
P009,1914+0D,117,75,68,42,89
P009,1933+0D,115,73,66,42,87.7
P009,1957+0D,119,76,69,43,89.7
P009,2019+0D,116,74,67,42,88.7
P009,2042+0D,114,72,65,42,86
P009,2101+0D,118,75,68,43,89
P009,2124+0D,115,73,66,42,87.7
P009,2147+0D,113,71,64,42,85.7
P009,2217+0D,94,58,54,36,70
P009,2259+0D,97,60,55,37,72.3
P009,2331+0D,92,56,52,36,68.7
P009,0008+1D,90,55,51,35,66.7
P009,0040+1D,95,58,54,37,70.3
P009,0115+1D,91,56,52,35,67.7
P009,0158+1D,88,53,50,35,64.7
P009,0242+1D,93,57,53,36,69
P009,0316+1D,89,54,50,35,65.7
P009,0350+1D,87,53,49,34,64.3
P009,0428+1D,91,56,52,35,67.7
P009,0509+1D,94,58,54,36,70
P009,0541+1D,88,53,50,35,64.7
P009,0618+1D,90,55,51,35,66.7
P009,0650+1D,92,56,52,36,68.7
P009,0725+1D,95,58,54,37,70.3
P009,0747+1D,98,60,56,38,72.7
P009,0809+1D,101,62,58,39,75
P009,0832+1D,104,64,60,40,77.3
P009,0855+1D,107,66,62,41,79.7
P009,0918+1D,110,68,64,42,81.3
P009,0939+1D,112,70,66,42,84
P010,0759+0D,153,97,79,56,115.7
P010,0818+0D,165,104,86,61,124.3
P010,0842+0D,148,94,77,54,111.3
P010,0901+0D,159,100,82,59,119.7
P010,0924+0D,170,107,88,63,128
P010,0947+0D,155,98,80,57,117
P010,1006+0D,146,92,75,54,110
P010,1029+0D,162,102,84,60,122
P010,1051+0D,151,95,78,56,113.7
P010,1113+0D,168,106,87,62,126.7
P010,1135+0D,157,99,81,58,118.3
P010,1158+0D,149,93,76,56,111.7
P010,1217+0D,164,103,85,61,123.3
P010,1239+0D,153,97,79,56,115.7
P010,1303+0D,172,109,89,63,130
P010,1322+0D,150,94,77,56,112.7
P010,1346+0D,160,101,83,59,120.7
P010,1409+0D,156,98,80,58,117.3
P010,1428+0D,147,92,75,55,109.7
P010,1451+0D,163,103,84,60,123
P010,1514+0D,152,96,79,56,114.7
P010,1533+0D,169,107,88,62,127.7
P010,1557+0D,158,100,82,58,119.3
P010,1619+0D,145,91,74,54,108.7
P010,1638+0D,161,101,83,60,121
P010,1702+0D,154,97,79,57,116
P010,1724+0D,171,108,89,63,129
P010,1743+0D,150,94,77,56,112.7
P010,1806+0D,166,105,86,61,125.3
P010,1829+0D,157,99,81,58,118.3
P010,1848+0D,148,93,76,55,111.7
P010,1912+0D,162,102,84,60,122
P010,1935+0D,153,97,79,56,115.7
P010,1958+0D,169,107,88,62,127.7
P010,2017+0D,155,98,80,57,117
P010,2041+0D,149,93,76,56,111.7
P010,2104+0D,164,103,85,61,123.3
P010,2127+0D,156,98,80,58,117.3
P010,2150+0D,150,94,77,56,112.7
P010,2228+0D,146,94,76,52,111.3
P010,2311+0D,151,96,79,55,114.3
P010,2350+0D,148,95,77,53,112.7
P010,0033+1D,155,98,80,57,117
P010,0106+1D,143,91,74,52,108.3
P010,0149+1D,150,95,78,55,113.3
P010,0234+1D,147,94,76,53,111.7
P010,0309+1D,153,97,79,56,115.7
P010,0347+1D,145,92,75,53,109.7
P010,0420+1D,149,95,78,54,112.7
P010,0455+1D,152,96,79,56,114.7
P010,0538+1D,148,94,76,54,111.3
P010,0619+1D,154,97,79,57,116
P010,0702+1D,146,93,75,53,110.7
P010,0736+1D,150,95,78,55,113.3
P010,0758+1D,156,98,80,58,117.3
P010,0819+1D,149,95,77,54,112.7
P010,0843+1D,158,100,82,58,119.3
"

# --- 2. Helper Functions ---

# --- 2.1 Time Conversion --- (Unchanged)
time_string_to_minutes <- function(time_str) {
  if (is.na(time_str)) return(NA_integer_)
  time_str <- trimws(time_str)
  if (str_detect(time_str, "^\\d{4}\\+\\d+D$")) {
    hour <- suppressWarnings(as.integer(str_sub(time_str, 1, 2)))
    minute <- suppressWarnings(as.integer(str_sub(time_str, 3, 4)))
    day_num <- suppressWarnings(as.integer(str_extract(time_str, "(?<=\\+)\\d+(?=D)")))
  } else if (str_detect(time_str, "^\\d{4}$")) { # Handle HHMM format (assumed Day 0)
    hour <- suppressWarnings(as.integer(str_sub(time_str, 1, 2)))
    minute <- suppressWarnings(as.integer(str_sub(time_str, 3, 4)))
    day_num <- 0L
  } else { return(NA_integer_) }
  if (is.na(hour) || is.na(minute) || is.na(day_num) || hour < 0 || hour > 23 || minute < 0 || minute > 59 || day_num < 0) { return(NA_integer_) }
  total_minutes <- day_num * 24 * 60 + hour * 60 + minute
  return(total_minutes)
}

minutes_to_formatted_string <- function(total_minutes) {
  if (is.na(total_minutes) || !is.finite(total_minutes) || total_minutes < 0) { return(NA_character_) }
  total_minutes <- as.integer(total_minutes)
  day_num <- total_minutes %/% (24 * 60)
  minutes_in_day <- total_minutes %% (24 * 60)
  hour <- minutes_in_day %/% 60
  minute <- minutes_in_day %% 60
  time_str <- sprintf("Day%d %02d:%02d", day_num + 1, hour, minute)
  return(time_str)
}

minutes_to_time_string <- function(total_minutes) {
  if (is.na(total_minutes) || total_minutes < 0) { return(NA_character_) }
  total_minutes <- as.integer(total_minutes)
  day_num <- total_minutes %/% (24 * 60)
  minutes_in_day <- total_minutes %% (24 * 60)
  hour <- minutes_in_day %/% 60
  minute <- minutes_in_day %% 60
  time_str <- sprintf("%02d%02d+%dD", hour, minute, day_num)
  return(time_str)
}

# --- 2.2 Data Loading and Preparation --- (Unchanged)
load_and_prepare_data <- function(df) {
  required_cols <- c("MASKID", "Time", "SBP", "DBP", "HR")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) { stop(paste("输入数据错误：必须包含以下列：", paste(missing_cols, collapse = ", "))) }
  
  df$MASKID <- as.character(df$MASKID)
  df$Time <- as.character(df$Time)
  numeric_cols_base <- c("SBP", "DBP", "HR")
  numeric_cols_optional <- c("PP", "MAP")
  numeric_cols <- c(numeric_cols_base, intersect(numeric_cols_optional, colnames(df)))
  
  # Convert relevant columns to numeric, handle potential errors
  for (col in numeric_cols) {
    if (col %in% colnames(df)) {
      if (!is.numeric(df[[col]])) {
        original_values <- df[[col]]
        suppressWarnings({ df[[col]] <- as.numeric(as.character(df[[col]])) })
        na_introduced <- is.na(df[[col]]) & !is.na(original_values) & original_values != ""
        if (any(na_introduced)) { warning(paste("在将列 '", col, "' 转换为数值型时引入了 NA 值。请检查原始数据中非数值的内容。"), call. = FALSE) }
      }
    }
  }
  
  # Calculate PP if missing or has NAs
  calculate_pp <- FALSE; if (!"PP" %in% colnames(df)) { calculate_pp <- TRUE; df$PP <- NA_real_ } else if (any(is.na(df$PP))) { calculate_pp <- TRUE }
  if (calculate_pp) {
    if ("SBP" %in% colnames(df) && "DBP" %in% colnames(df) && is.numeric(df$SBP) && is.numeric(df$DBP)) {
      # Only calculate where PP is NA and SBP/DBP are not NA
      df <- df %>% mutate(PP = ifelse(is.na(PP) & !is.na(SBP) & !is.na(DBP), SBP - DBP, PP))
    } else { warning("无法计算部分或全部 PP，因为 SBP 或 DBP 缺失或不是数值型。", call. = FALSE) }
  }
  
  # Calculate MAP if missing or has NAs
  calculate_map <- FALSE; if (!"MAP" %in% colnames(df)) { calculate_map <- TRUE; df$MAP <- NA_real_ } else if (any(is.na(df$MAP))) { calculate_map <- TRUE }
  if (calculate_map) {
    if ("SBP" %in% colnames(df) && "DBP" %in% colnames(df) && is.numeric(df$SBP) && is.numeric(df$DBP)) {
      # Only calculate where MAP is NA and SBP/DBP are not NA
      df <- df %>% mutate(MAP = ifelse(is.na(MAP) & !is.na(SBP) & !is.na(DBP), DBP + (1/3) * (SBP - DBP), MAP))
    } else {warning("无法计算部分或全部 MAP，因为 SBP 或 DBP 缺失或不是数值型。", call. = FALSE) }
  }
  
  # Add Time related columns
  df <- df %>%
    mutate(
      Total_Minutes = sapply(Time, time_string_to_minutes),
      Day = ifelse(!is.na(Total_Minutes), Total_Minutes %/% (24*60), NA_integer_),
      Hour = ifelse(!is.na(Total_Minutes), (Total_Minutes %% (24*60)) %/% 60, NA_integer_)
    )
  if (any(is.na(df$Total_Minutes))) { warning("部分 'Time' 值无法转换为 Total_Minutes。请检查格式 (应为 HHMM+DD 或 HHMM)。受影响的行可能被排除或导致后续错误。", call. = FALSE) }
  
  # Check final metric columns
  metric_cols_final <- c("SBP", "DBP", "HR", "PP", "MAP")
  for(col in metric_cols_final) {
    if (!col %in% colnames(df)) {
      if(col %in% c("PP", "MAP")){ warning(paste("数据准备后：可选指标列 '", col, "' 缺失或包含NA，计算可能不完整。"), call. = FALSE) }
      else { warning(paste("数据准备后：必需指标列 '", col, "' 缺失。"), call. = FALSE) }
    } else if (!is.numeric(df[[col]])) {
      warning(paste("数据准备后：列 '", col, "' 不是数值型。可能存在未处理的非数值数据。"), call. = FALSE)
      suppressWarnings({ df[[col]] <- as.numeric(df[[col]]) }) # Attempt conversion again if needed
    }
  }
  
  # Remove rows with NA in essential processing columns
  essential_cols_for_processing <- c("MASKID", "Total_Minutes", "SBP", "DBP", "HR")
  rows_before <- nrow(df)
  essential_cols_present <- intersect(essential_cols_for_processing, colnames(df))
  if (length(essential_cols_present) > 0) {
    # Check for NA values in the essential columns before attempting drop_na
    na_check <- rowSums(is.na(df[, essential_cols_present, drop = FALSE])) > 0
    if (any(na_check)) {
      df <- df[!na_check, , drop = FALSE]
    }
  } else {
    warning("无法执行基于必需列的 NA 移除，因为部分必需列缺失。", call. = FALSE)
  }
  rows_after <- nrow(df)
  if (rows_after < rows_before) { warning(paste(rows_before - rows_after, " 行因在 MASKID, Time(转换后), SBP, DBP 或 HR 中存在缺失值而被移除。"), call. = FALSE) }
  
  # Select and order columns
  cols_order <- c("MASKID", "Time", "Total_Minutes", "Day", "Hour", "SBP", "DBP", "HR", "PP", "MAP")
  other_cols <- setdiff(colnames(df), cols_order)
  # Ensure cols_order only includes columns actually present in df
  cols_order_present <- intersect(cols_order, colnames(df))
  df <- df %>% select(all_of(cols_order_present), all_of(other_cols))
  
  return(df)
}

# --- 2.3 Data Transformation (Wide Format) --- (Unchanged)
create_wide_data_per_metric <- function(long_data,
                                        day_start1_h, day_start1_m,
                                        night_start1_h, night_start1_m,
                                        day_start2_h, day_start2_m,
                                        night_start2_h, night_start2_m) {
  
  if (!"Time" %in% colnames(long_data) || !"Total_Minutes" %in% colnames(long_data)) { stop("错误 (create_wide_data_per_metric): 'long_data' 必须包含 'Time' 和 'Total_Minutes' 列。") }
  if(any(is.na(long_data$Total_Minutes))) { warning("create_wide_data_per_metric: 输入的 long_data 包含 NA 的 Total_Minutes 值。这些行将被忽略。", call. = FALSE); long_data <- long_data %>% filter(!is.na(Total_Minutes)) }
  if (nrow(long_data) == 0) { stop("错误 (create_wide_data_per_metric): 过滤 NA Total_Minutes 后，long_data 为空。") }
  
  # Validate time inputs
  time_inputs_h <- c(day_start1_h, night_start1_h, day_start2_h, night_start2_h)
  time_inputs_m <- c(day_start1_m, night_start1_m, day_start2_m, night_start2_m)
  if(any(is.na(time_inputs_h)) || any(!sapply(time_inputs_h, function(x) is.numeric(x) && x >= 0 && x <= 23 && x == floor(x)))) { stop("错误 (create_wide_data_per_metric): 日间/夜间小时必须是 0 到 23 之间的整数。") }
  if(any(is.na(time_inputs_m)) || any(!sapply(time_inputs_m, function(x) is.numeric(x) && x >= 0 && x <= 59 && x == floor(x)))) { stop("错误 (create_wide_data_per_metric): 日间/夜间分钟必须是 0 到 59 之间的整数。") }
  
  # Define boundary times
  boundary_times <- c(
    sprintf("%02d%02d+0D", as.integer(day_start1_h), as.integer(day_start1_m)), # Day 1 Start
    sprintf("%02d%02d+0D", as.integer(night_start1_h), as.integer(night_start1_m)), # Day 1 Night Start
    sprintf("%02d%02d+1D", as.integer(day_start2_h), as.integer(day_start2_m)),   # Day 2 Start
    sprintf("%02d%02d+1D", as.integer(night_start2_h), as.integer(night_start2_m))  # Day 2 Night Start (Used as end for D2 Day)
  )
  
  # Get all unique time points (observed + boundaries) and sort them
  observed_times <- unique(long_data$Time[!is.na(long_data$Time)])
  all_times <- sort(unique(c(observed_times, boundary_times)))
  all_minutes_list <- sapply(all_times, time_string_to_minutes, USE.NAMES = FALSE)
  
  # Create a map and filter out any times that couldn't be converted
  time_minute_map <- data.frame(Time = all_times, Total_Minutes = all_minutes_list) %>%
    filter(!is.na(Total_Minutes)) %>%
    arrange(Total_Minutes)
  
  all_times_sorted <- time_minute_map$Time
  all_minutes_sorted <- time_minute_map$Total_Minutes
  names(all_minutes_sorted) <- all_times_sorted # Name minutes vector with time strings
  
  # Metrics to process
  metrics <- c("SBP", "DBP", "HR", "PP", "MAP")
  wide_dfs <- list()
  metrics_present <- intersect(metrics, colnames(long_data))
  if(length(metrics_present) == 0) { stop("错误 (create_wide_data_per_metric): long_data 中不包含任何要处理的指标列 (SBP, DBP, HR, PP, MAP)。") }
  
  for (metric in metrics_present) {
    # Ensure the metric column exists and is numeric
    if (!is.numeric(long_data[[metric]]) || all(is.na(long_data[[metric]]))) {
      warning(paste("指标 '", metric, "' 在 long_data 中不是数值型或全为 NA。跳过为此指标创建宽格式数据。"), call. = FALSE)
      next # Skip to the next metric
    }
    
    # Filter for the current metric, ensure it's numeric, and pivot
    long_data_metric_filtered <- long_data %>%
      select(MASKID, Time, all_of(metric)) %>%
      filter(Time %in% all_times_sorted) %>% # Filter based on successfully converted and sorted times
      mutate(across(all_of(metric), as.numeric)) # Ensure numeric
    
    # Check if there are any rows left after filtering
    if(nrow(long_data_metric_filtered) == 0) {
      warning(paste("指标 '", metric, "' 在过滤有效时间点后没有数据。跳过此指标的宽格式转换。"), call. = FALSE)
      next
    }
    
    long_data_wide <- long_data_metric_filtered %>%
      pivot_wider(names_from = Time,
                  values_from = all_of(metric),
                  id_cols = MASKID,
                  values_fn = function(x) mean(x, na.rm = TRUE)) # Handle duplicates by averaging
    
    # Add columns for any time points that were missing in the pivot (assign NA)
    missing_times <- setdiff(all_times_sorted, colnames(long_data_wide)[-1])
    for (mt in missing_times) {
      long_data_wide[[mt]] <- NA_real_
    }
    
    # Ensure final column order matches the sorted times
    final_cols_order <- c("MASKID", all_times_sorted)
    final_cols_order_present <- intersect(final_cols_order, colnames(long_data_wide))
    
    wide_dfs[[metric]] <- long_data_wide %>% select(all_of(final_cols_order_present))
  }
  
  if (length(wide_dfs) == 0) { warning("在 create_wide_data_per_metric 中未能为任何指标生成有效的宽格式数据框。") }
  
  return(list(wide_dfs = wide_dfs, sorted_times = all_times_sorted, sorted_minutes = all_minutes_sorted))
}

# --- 2.4 Interpolation --- (Unchanged)
interpolate_wide_data_per_metric <- function(wide_dfs, sorted_minutes) {
  metrics <- names(wide_dfs)
  interpolated_dfs <- list()
  if (length(sorted_minutes) == 0) { stop("错误 (interpolate_wide_data_per_metric): sorted_minutes 为空，无法插值。") }
  
  for (metric in metrics) {
    wide_df <- wide_dfs[[metric]]
    
    # Basic validation of the input dataframe
    if (is.null(wide_df) || !is.data.frame(wide_df) || nrow(wide_df) == 0) {
      warning(paste("输入插补的 wide_df 为空或 NULL for metric", metric), call. = FALSE)
      interpolated_dfs[[metric]] <- wide_df # Return original (empty/null)
      next
    }
    if (ncol(wide_df) <= 1) { # Only MASKID column
      warning(paste("输入插补的 wide_df 仅包含 MASKID 列 for metric", metric), call. = FALSE)
      interpolated_dfs[[metric]] <- wide_df # Return original
      next
    }
    
    interpolated_df <- wide_df
    time_cols <- colnames(wide_df)[-1] # Exclude MASKID
    expected_cols <- length(sorted_minutes)
    
    # Check if the number of time columns matches the sorted_minutes length
    if (length(time_cols) != expected_cols) {
      warning(paste("宽格式数据框指标", metric, "的列数 (", length(time_cols), ") 与预期的时间点数 (", expected_cols, ") 不匹配。跳过此指标的插补。"), call. = FALSE)
      interpolated_dfs[[metric]] <- wide_df # Return original
      next
    }
    
    for (i in 1:nrow(wide_df)) {
      patient_id <- interpolated_df$MASKID[i]
      metric_data_raw <- unlist(interpolated_df[i, time_cols], use.names = FALSE)
      metric_data <- suppressWarnings(as.numeric(metric_data_raw)) # Ensure numeric
      
      # Check if conversion resulted in correct length
      if (length(metric_data) != length(time_cols)) {
        warning(paste("患者", patient_id, "指标", metric, "的数据提取/转换后长度 (", length(metric_data), ") 与预期列数 (", length(time_cols), ") 不匹配。跳过此行的插补。"), call. = FALSE)
        next # Skip this row for interpolation
      }
      
      final_values_to_assign <- metric_data # Default to original data
      
      # Perform interpolation only if there are NAs and at least 2 non-NA points
      if (any(is.na(metric_data)) && sum(!is.na(metric_data)) >= 2) {
        interpolated_result <- tryCatch({
          # Use na.approx for linear interpolation, rule=1 means no extrapolation
          # Need to provide xout for alignment if original x had NAs
          # zoo object requires unique index, sorted_minutes should be unique and sorted
          if(any(duplicated(sorted_minutes))) {
            warning(paste("Duplicate values found in sorted_minutes for interpolation of", metric, ". Using first occurrence."), call.=FALSE)
            unique_indices <- !duplicated(sorted_minutes)
            metric_data_zoo <- zoo(metric_data[unique_indices], sorted_minutes[unique_indices])
            interpolated_zoo <- na.approx(metric_data_zoo, xout = sorted_minutes, na.rm = FALSE, rule = 1)
          } else {
            metric_data_zoo <- zoo(metric_data, sorted_minutes)
            interpolated_zoo <- na.approx(metric_data_zoo, xout = sorted_minutes, na.rm = FALSE, rule = 1)
          }
          
          final_vals <- as.numeric(zoo::coredata(interpolated_zoo))
          
          # Verify output length
          if (length(final_vals) == length(time_cols)) {
            final_vals
          } else {
            warning(paste("Interpolation produced unexpected length for patient", patient_id, "metric", metric, ". Expected", length(time_cols), "got", length(final_vals), ". Falling back to original data for this row."), call. = FALSE)
            metric_data # Fallback
          }
        }, error = function(e) {
          warning(paste("zoo::na.approx 对患者", patient_id, "指标", metric, "失败:", e$message, ". 将保留原始数据（可能含NA）。"), call. = FALSE)
          return(metric_data) # Return original data on error
        })
        final_values_to_assign <- interpolated_result
      }
      
      # Assign back to the dataframe if lengths match
      if (length(final_values_to_assign) == length(time_cols)) {
        tryCatch({
          # Ensure the values are assignable (atomic vector or list of same length)
          if (is.atomic(final_values_to_assign)) {
            interpolated_df[i, time_cols] <- as.list(final_values_to_assign)
          } else {
            warning(paste("Skipping assignment for patient", patient_id, "metric", metric, "row", i, "as final_values_to_assign is not atomic."), call. = FALSE)
          }
        }, error = function(e) {
          warning(paste("Assignment failed for patient", patient_id, "metric", metric, "row", i, ":", e$message), call. = FALSE)
        })
      } else {
        warning(paste("最终赋值前检查：值的数量 (", length(final_values_to_assign), ") 与患者 ", patient_id, ", 指标 ", metric, " 的列数 (", length(time_cols), ") 不匹配。未更新此行/指标。"), call. = FALSE)
      }
    }
    interpolated_dfs[[metric]] <- interpolated_df
  }
  return(interpolated_dfs)
}

# --- 2.5 Data Splitting (Day/Night) --- (Unchanged)
split_wide_data_day_night <- function(interpolated_dfs, sorted_times, sorted_minutes,
                                      day_start1_h, day_start1_m,
                                      night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m,
                                      night_start2_h, night_start2_m) {
  metrics <- names(interpolated_dfs)
  if (length(metrics) == 0) { warning("split_wide_data_day_night: 输入的 interpolated_dfs 为空。", call. = FALSE); return(list()) }
  
  # Validate time inputs
  required_h <- c(day_start1_h, night_start1_h, day_start2_h, night_start2_h)
  required_m <- c(day_start1_m, night_start1_m, day_start2_m, night_start2_m)
  if(any(is.na(required_h)) || any(!sapply(required_h, is.numeric)) || any(required_h < 0 | required_h > 23)) { stop("错误 (split_wide_data_day_night): 日间/夜间小时必须是 0 到 23 之间的有效数值。") }
  if(any(is.na(required_m)) || any(!sapply(required_m, is.numeric)) || any(required_m < 0 | required_m > 59)) { stop("错误 (split_wide_data_day_night): 日间/夜间分钟必须是 0 到 59 之间的有效数值。") }
  
  # Validate sorted time inputs
  if(length(sorted_times) != length(sorted_minutes)) { stop("错误 (split_wide_data_day_night): sorted_times 和 sorted_minutes 长度不匹配。") }
  if(length(sorted_times) == 0) { warning("split_wide_data_day_night: sorted_times/sorted_minutes 为空，无法分割。", call.=FALSE); return(list()) }
  
  # Define time boundaries in total minutes from the start (00:00+0D)
  d1_day_start_min   <- day_start1_h * 60 + day_start1_m
  d1_night_start_min <- night_start1_h * 60 + night_start1_m
  d2_day_start_min   <- (24 * 60) + (day_start2_h * 60 + day_start2_m)
  d2_night_start_min <- (24 * 60) + (night_start2_h * 60 + night_start2_m)
  
  # Define PERIOD ENDS (exclusive of the next start time)
  d0_night_end_min   <- d1_day_start_min
  d1_day_end_min     <- d1_night_start_min
  d1_night_end_min   <- d2_day_start_min
  d2_day_end_min     <- d2_night_start_min
  
  # Get indices for each period based on sorted_minutes
  cols_idx_d0_night <- which(sorted_minutes < d0_night_end_min)
  cols_idx_d1_day   <- which(sorted_minutes >= d1_day_start_min & sorted_minutes < d1_day_end_min)
  cols_idx_d1_night <- which(sorted_minutes >= d1_night_start_min & sorted_minutes < d1_night_end_min)
  cols_idx_d2_day   <- which(sorted_minutes >= d2_day_start_min & sorted_minutes < d2_day_end_min)
  
  # Get the corresponding time column names
  cols_d0_night <- sorted_times[cols_idx_d0_night]
  cols_d1_day   <- sorted_times[cols_idx_d1_day]
  cols_d1_night <- sorted_times[cols_idx_d1_night]
  cols_d2_day   <- sorted_times[cols_idx_d2_day]
  
  # Initialize results list
  split_results <- list(
    day0_night = list(),
    day1_day = list(),
    day1_night = list(),
    day2_day = list()
  )
  
  # Populate results for each metric
  for (metric in metrics) {
    df_metric <- interpolated_dfs[[metric]]
    if (is.null(df_metric) || !is.data.frame(df_metric) || !"MASKID" %in% colnames(df_metric)) {
      warning(paste("split_wide_data_day_night: 跳过指标", metric, "，因为其插补数据无效或缺少 MASKID。"), call. = FALSE)
      next
    }
    
    # Select columns for each period. Use any_of to avoid errors if a period has no columns.
    split_results$day0_night[[metric]] <- df_metric %>% select(MASKID, any_of(cols_d0_night))
    split_results$day1_day[[metric]]   <- df_metric %>% select(MASKID, any_of(cols_d1_day))
    split_results$day1_night[[metric]] <- df_metric %>% select(MASKID, any_of(cols_d1_night))
    split_results$day2_day[[metric]]   <- df_metric %>% select(MASKID, any_of(cols_d2_day))
  }
  
  return(split_results)
}

# --- 2.6 Calculation Functions ---
# --- 2.6.1 Trapezoid Area (Unchanged) ---
trapezoid_area <- function(y1, y2, dx) {
  if(is.numeric(y1) && is.numeric(y2) && is.numeric(dx) &&
     !is.na(y1) && !is.na(y2) && !is.na(dx) && dx >= 0){
    return(0.5 * (y1 + y2) * dx)
  } else {
    return(0)
  }
}

# --- 2.6.2 Area/Time Calculation (Unchanged) ---
calculate_areas_times_single_row <- function(row_data, time_points, region_b_upper, region_b_lower) {
  row_data <- as.numeric(row_data)
  time_points <- as.numeric(time_points)
  
  if (!is.numeric(time_points) || length(time_points) == 0) {
    warning("calculate_areas_times_single_row: time_points must be a non-empty numeric vector.", call. = FALSE)
    return(list(Sa=NA, Sc=NA, Sd=NA, AUC=NA, Ts1_total=NA, Ts2_total=NA, Ts3_total=NA))
  }
  if (length(row_data) != length(time_points)) {
    warning("calculate_areas_times_single_row: row_data and time_points lengths differ.", call. = FALSE)
    return(list(Sa=NA, Sc=NA, Sd=NA, AUC=NA, Ts1_total=NA, Ts2_total=NA, Ts3_total=NA))
  }
  if (!is.na(region_b_upper) && (!is.numeric(region_b_upper) || !is.finite(region_b_upper))) region_b_upper <- NA_real_
  if (!is.na(region_b_lower) && (!is.numeric(region_b_lower) || !is.finite(region_b_lower))) region_b_lower <- NA_real_
  
  if (!is.na(region_b_upper) && !is.na(region_b_lower) && region_b_upper <= region_b_lower) {
    warning("calculate_areas_times_single_row: region_b_upper must be strictly greater than region_b_lower when both are provided.", call. = FALSE)
  }
  
  valid_indices <- which(is.finite(row_data) & is.finite(time_points))
  row_data <- row_data[valid_indices]
  time_points <- time_points[valid_indices]
  
  if (is.unsorted(time_points)) {
    sort_order <- order(time_points)
    row_data <- row_data[sort_order]
    time_points <- time_points[sort_order]
    warning("calculate_areas_times_single_row: time_points were not sorted, applying sort.", call. = FALSE)
  }
  
  Sa <- 0; Sc <- 0; Sd <- 0; Ts1 <- 0; Ts2 <- 0; Ts3 <- 0
  n_points <- length(row_data)
  
  if (n_points < 2) {
    return(list(Sa=0, Sc=0, Sd=0, AUC=0, Ts1_total=0, Ts2_total=0, Ts3_total=0))
  }
  
  has_upper <- is.finite(region_b_upper)
  has_lower <- is.finite(region_b_lower)
  
  for (i in 1:(n_points - 1)) {
    current_y <- row_data[i]
    next_y <- row_data[i + 1]
    current_t <- time_points[i]
    next_t <- time_points[i+1]
    
    if (is.na(current_y) || is.na(next_y) || is.na(current_t) || is.na(next_t)) next
    
    dx <- next_t - current_t
    
    if (is.na(dx) || dx < 0) {
      if(!is.na(dx) && dx < 0) warning(paste("calculate_areas_times_single_row: 检测到负的时间差 (dx):", dx, "，区间", i, "。跳过此区间。"), call. = FALSE)
      next
    }
    if (dx == 0) next
    
    # Calculate total area (AUC/Sd) regardless of limits
    Sd <- Sd + trapezoid_area(current_y, next_y, dx)
    
    # Determine region for current and next point
    get_region <- function(y, upper, lower, has_u, has_l) {
      if (has_u && y > upper) return("above")
      if (has_l && y < lower) return("below")
      if ((!has_u || y <= upper) && (!has_l || y >= lower)) return("between")
      return("undefined") # Should only happen if limits are nonsensical (e.g., lower > upper) or both missing
    }
    
    region_current <- get_region(current_y, region_b_upper, region_b_lower, has_upper, has_lower)
    region_next <- get_region(next_y, region_b_upper, region_b_lower, has_upper, has_lower)
    
    if (region_current == "above" && region_next == "above" && has_upper) {
      Sa <- Sa + trapezoid_area(current_y - region_b_upper, next_y - region_b_upper, dx)
      Ts1 <- Ts1 + dx
    } else if (region_current == "below" && region_next == "below" && has_lower) {
      Sc <- Sc + trapezoid_area(region_b_lower - current_y, region_b_lower - next_y, dx)
      Ts3 <- Ts3 + dx
    } else if (region_current == "between" && region_next == "between") {
      Ts2 <- Ts2 + dx
    } else { # Transition between regions or handling undefined regions due to missing limits
      denominator <- next_y - current_y
      
      # Calculate crossing times, handle vertical lines (denominator == 0)
      t_cross_upper <- NA; y_cross_upper <- NA
      if (has_upper && abs(denominator) > 1e-10 && (current_y - region_b_upper) * (next_y - region_b_upper) < 0) {
        t_cross_upper <- current_t + dx * (region_b_upper - current_y) / denominator
        y_cross_upper <- region_b_upper
      }
      
      t_cross_lower <- NA; y_cross_lower <- NA
      if (has_lower && abs(denominator) > 1e-10 && (current_y - region_b_lower) * (next_y - region_b_lower) < 0) {
        t_cross_lower <- current_t + dx * (region_b_lower - current_y) / denominator
        y_cross_lower <- region_b_lower
      }
      
      # Collect points for the segment: Start, Crossings (if any), End
      segment_points <- list(list(t = current_t, y = current_y))
      crossings <- list()
      if (!is.na(t_cross_upper)) crossings <- c(crossings, list(list(t = t_cross_upper, y = y_cross_upper)))
      if (!is.na(t_cross_lower)) crossings <- c(crossings, list(list(t = t_cross_lower, y = y_cross_lower)))
      
      # Sort crossings by time if both exist
      if (length(crossings) > 0) {
        # Filter out crossings outside the current time segment (can happen due to floating point)
        crossings <- crossings[sapply(crossings, function(pt) pt$t >= current_t & pt$t <= next_t)] # Keep points exactly on boundary
        if(length(crossings) > 0) {
          crossings <- crossings[order(sapply(crossings, `[[`, "t"))]
          # Remove duplicate times (can happen if crossing is exactly at start/end)
          times_only <- sapply(c(list(segment_points[[1]]), crossings, list(list(t = next_t, y = next_y))), `[[`, "t")
          unique_indices <- !duplicated(round(times_only, 6)) # Round to avoid floating point issues
          segment_points <- c(list(segment_points[[1]]), crossings, list(list(t = next_t, y = next_y)))[unique_indices]
        } else {
          segment_points <- c(segment_points, list(list(t = next_t, y = next_y)))
        }
      } else {
        segment_points <- c(segment_points, list(list(t = next_t, y = next_y)))
      }
      
      
      # Iterate through sub-segments defined by crossings
      for (j in 1:(length(segment_points) - 1)) {
        pt1 <- segment_points[[j]]
        pt2 <- segment_points[[j+1]]
        sub_dx <- pt2$t - pt1$t
        
        if(is.na(sub_dx) || sub_dx <= 1e-9) next # Skip zero or negligible time segments
        
        # Determine the region of this sub-segment (based on midpoint or start point)
        # Use midpoint, slightly more robust for vertical segments crossing a boundary
        mid_y <- (pt1$y + pt2$y) / 2
        sub_region <- get_region(mid_y, region_b_upper, region_b_lower, has_upper, has_lower)
        
        if (sub_region == "above" && has_upper) {
          Sa <- Sa + trapezoid_area(pt1$y - region_b_upper, pt2$y - region_b_upper, sub_dx)
          Ts1 <- Ts1 + sub_dx
        } else if (sub_region == "below" && has_lower) {
          Sc <- Sc + trapezoid_area(region_b_lower - pt1$y, region_b_lower - pt2$y, sub_dx)
          Ts3 <- Ts3 + sub_dx
        } else { # Between or undefined (e.g., missing limits)
          Ts2 <- Ts2 + sub_dx
        }
      }
    }
  }
  
  # Assign NA if limits were missing for Sa or Sc
  if(!has_upper) Sa <- NA_real_
  if(!has_lower) Sc <- NA_real_
  
  return(list(Sa = Sa, Sc = Sc, Sd = Sd, AUC = Sd, Ts1_total = Ts1, Ts2_total = Ts2, Ts3_total = Ts3))
}

# --- 2.6.3 Basic Statistics Calculation (MODIFIED to return n_over, n_total) ---
calculate_statistics_single_row <- function(row_data, time_points, region_b_upper) {
  row_data <- as.numeric(row_data)
  valid_data <- row_data[is.finite(row_data)]
  n_valid <- length(valid_data)
  
  if (n_valid == 0) {
    return(list(max_value=NA, min_value=NA, Delta=NA, mean=NA, SD=NA, CV=NA, ARV=NA, Load=NA, n_over = 0, n_total = 0))
  }
  
  max_val <- max(valid_data)
  min_val <- min(valid_data)
  range_val <- max_val - min_val
  mean_val <- mean(valid_data)
  
  std_dev <- if (n_valid > 1) sd(valid_data) else if (n_valid == 1) 0 else NA_real_
  
  cv <- if (!is.na(mean_val) && abs(mean_val) > 1e-9 && !is.na(std_dev) && is.finite(std_dev)) (std_dev / abs(mean_val)) * 100 else NA_real_
  
  # ARV calculation based on only valid (finite) points
  arv <- NA_real_
  if (n_valid > 1) {
    diffs <- abs(diff(valid_data)) # Use the filtered valid_data
    arv <- mean(diffs, na.rm = TRUE)
    if (!is.finite(arv)) arv <- NA_real_
  }
  
  points_above_upper <- 0 # Default
  load_perc <- NA_real_
  if (is.numeric(region_b_upper) && is.finite(region_b_upper)) {
    points_above_upper <- sum(valid_data > region_b_upper, na.rm = TRUE)
    load_perc <- (points_above_upper / n_valid) * 100
  } else {
    # warning("calculate_statistics_single_row: region_b_upper is non-numeric or NA. Load cannot be calculated.", call.=FALSE)
    # Keep Load NA, but counts can still be 0
  }
  
  return(list(max_value=max_val, min_value=min_val, Delta=range_val, mean=mean_val,
              SD=std_dev, CV=cv, ARV=arv, Load=load_perc,
              n_over = points_above_upper, n_total = n_valid)) # Return counts
}

# --- 2.6.4 Ratio Calculation (Unchanged) ---
calculate_ratios_single_row <- function(area_time_results, region_b_upper, region_b_lower) {
  sa_val <- area_time_results$Sa
  sc_val <- area_time_results$Sc
  sd_val <- area_time_results$Sd
  ts1 <- area_time_results$Ts1_total
  ts2 <- area_time_results$Ts2_total
  ts3 <- area_time_results$Ts3_total
  
  # Check only essential calculated values for finiteness
  essential_numeric <- c(sd_val, ts1, ts2, ts3) # Sa/Sc can be NA if limits are NA
  if(any(!sapply(essential_numeric, is.numeric)) || any(!sapply(essential_numeric, is.finite))) {
    warning("calculate_ratios_single_row: Input area/time results (Sd, Ts1, Ts2, Ts3) contain NA/non-finite values. Ratios may be NA.", call.=FALSE)
    # Set defaults to NA
    Se <- NA_real_; Sf <- NA_real_; hyper_Burden <- NA_real_; hypo_Burden <- NA_real_
    cumulative_Load <- NA_real_; TTR <- NA_real_; TOTR <- NA_real_; TUTR <- NA_real_
  } else {
    has_upper <- is.numeric(region_b_upper) && is.finite(region_b_upper)
    has_lower <- is.numeric(region_b_lower) && is.finite(region_b_lower)
    
    # Se and Sf are calculated based on the specific limits for the period
    Se <- if(has_upper) ts1 * region_b_upper else NA_real_
    Sf <- if(has_lower) ts3 * region_b_lower else NA_real_
    
    total_time <- ts1 + ts2 + ts3
    if (is.na(total_time) || !is.finite(total_time)) {
      warning("calculate_ratios_single_row: Total time (Ts1+Ts2+Ts3) is NA or non-finite. Time ratios will be NA.", call. = FALSE)
      total_time <- NA_real_ # Ensure it propagates NA
      TTR <- NA_real_; TOTR <- NA_real_; TUTR <- NA_real_
    } else {
      # Calculate time ratios only if total_time is valid and positive
      if (total_time > 1e-9) {
        TTR <- (ts2 / total_time) * 100
        TOTR <- (ts1 / total_time) * 100
        TUTR <- (ts3 / total_time) * 100
      } else { # If total time is zero or negligible, ratios are 0
        TTR <- 0; TOTR <- 0; TUTR <- 0
      }
    }
    
    # Hyper Burden (wTOR) - Requires Sa, Se, Ts1, total_time
    hyper_Burden <- NA_real_
    if(has_upper && is.finite(sa_val) && is.finite(Se) && is.finite(ts1) && is.finite(total_time)) { # Check all components
      denominator_wtor <- sa_val + Se
      if (total_time > 1e-9 && abs(denominator_wtor) > 1e-9) {
        hyper_Burden <- (sa_val / denominator_wtor) * (ts1 / total_time) * 100
      } else if (total_time > 1e-9 && abs(denominator_wtor) <= 1e-9 && abs(sa_val) < 1e-9) { # If Sa=0, Se=0 => Burden=0
        hyper_Burden <- 0
      } else if (total_time <= 1e-9) { # If total time is 0, burden is 0
        hyper_Burden <- 0
      }
    }
    
    # Hypo Burden (wTUR) - Requires Sc, Sf, Ts3, total_time
    hypo_Burden <- NA_real_
    if(has_lower && is.finite(sc_val) && is.finite(Sf) && is.finite(ts3) && is.finite(total_time)) { # Check all components
      # Note: Sf is denominator in first part
      if (total_time > 1e-9 && abs(Sf) > 1e-9) {
        hypo_Burden <- (sc_val / Sf) * (ts3 / total_time) * 100
      } else if (total_time > 1e-9 && abs(Sf) <= 1e-9 && abs(sc_val) < 1e-9) { # If Sc=0, Sf=0 => Burden=0
        hypo_Burden <- 0
      } else if (total_time <= 1e-9) { # If total time is 0, burden is 0
        hypo_Burden <- 0
      }
    }
    
    # Cumulative Load - Requires Sa, Sd
    cumulative_Load <- NA_real_
    if (is.finite(sa_val) && is.finite(sd_val)) {
      if (abs(sd_val) > 1e-9) { # Requires non-zero total area (Sd/AUC)
        cumulative_Load <- sa_val / sd_val * 100
      } else if (abs(sa_val) < 1e-9) { # If Sa is 0 and Sd is 0, load is 0
        cumulative_Load <- 0
      }
    }
  }
  
  return(list(
    Se = Se, Sf = Sf, # Return calculated Se/Sf for this period
    hyper_Burden = hyper_Burden, hypo_Burden = hypo_Burden,
    cumulative_Load = cumulative_Load,
    TTR = TTR, TOTR = TOTR, TUTR = TUTR
  ))
}

# --- 2.7 Calculation Orchestrator (Unchanged, used for Day, Night, 24h-Unified) ---
calculate_abpm_metrics_for_period <- function(wide_df, time_points, upper_limit, lower_limit) {
  
  if (is.null(wide_df) || !is.data.frame(wide_df) || nrow(wide_df) == 0 || !"MASKID" %in% colnames(wide_df)) {
    warning("calculate_abpm_metrics_for_period: 输入的 wide_df 无效、为空或缺少 MASKID 列。", call. = FALSE)
    return(data.frame(MASKID = character(0)))
  }
  if (is.null(time_points) || !is.numeric(time_points) || length(time_points) == 0) {
    warning("calculate_abpm_metrics_for_period: time_points 无效或为空。", call. = FALSE)
    MASKIDs <- if("MASKID" %in% colnames(wide_df)) wide_df$MASKID else character(0)
    return(data.frame(MASKID = MASKIDs))
  }
  
  time_cols <- colnames(wide_df)[-1]
  if (length(time_cols) != length(time_points)) {
    warning(paste("calculate_abpm_metrics_for_period: wide_df 的时间列数 (", length(time_cols),
                  ") 与 time_points 长度 (", length(time_points), ") 不匹配。"), call. = FALSE)
    MASKIDs <- if("MASKID" %in% colnames(wide_df)) wide_df$MASKID else character(0)
    return(data.frame(MASKID = MASKIDs))
  }
  # Allow NA limits, functions downstream will handle them
  if (!is.na(upper_limit) && (!is.numeric(upper_limit) || !is.finite(upper_limit))) {
    warning("calculate_abpm_metrics_for_period: upper_limit 如果提供，则必须是有效的数值。", call.=FALSE)
    upper_limit <- NA_real_ # Treat invalid as NA
  }
  if (!is.na(lower_limit) && (!is.numeric(lower_limit) || !is.finite(lower_limit))) {
    warning("calculate_abpm_metrics_for_period: lower_limit 如果提供，则必须是有效的数值。", call.=FALSE)
    lower_limit <- NA_real_ # Treat invalid as NA
  }
  
  num_rows <- nrow(wide_df)
  all_results <- list()
  
  for (i in 1:num_rows) {
    patient_id <- wide_df$MASKID[i]
    row_data_raw <- wide_df[i, time_cols]
    row_data <- suppressWarnings(as.numeric(unlist(row_data_raw)))
    
    if(length(row_data) != length(time_cols)) {
      warning(paste("calculate_abpm_metrics_for_period: Patient", patient_id, " - Data conversion failed or resulted in wrong length for row. Skipping calculation for this patient."), call.=FALSE)
      next
    }
    
    area_time_res <- calculate_areas_times_single_row(row_data, time_points, upper_limit, lower_limit)
    # Calculate stats, including n_over/n_total based on the period's upper limit
    stats_res_full <- calculate_statistics_single_row(row_data, time_points, upper_limit)
    # Extract only the relevant stats for this function's main purpose (exclude counts here)
    stats_res <- stats_res_full[c("max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "Load")]
    
    ratio_res <- calculate_ratios_single_row(area_time_res, upper_limit, lower_limit)
    
    # Combine all results
    patient_results <- c(list(MASKID = patient_id), area_time_res, stats_res, ratio_res)
    all_results[[i]] <- patient_results
  }
  
  if(length(all_results) == 0) {
    warning("calculate_abpm_metrics_for_period: No valid results generated for any patient.", call.=FALSE)
    MASKIDs <- if("MASKID" %in% colnames(wide_df)) wide_df$MASKID else character(0)
    return(data.frame(MASKID = MASKIDs))
  }
  
  # Use bind_rows with .id to handle potential list structure issues if some results are NULL
  results_df <- bind_rows(all_results)
  
  # Check if bind_rows resulted in an empty df or just MASKID
  if (nrow(results_df) == 0 || (ncol(results_df) == 1 && "MASKID" %in% names(results_df)) || all(sapply(results_df %>% select(-any_of("MASKID")), function(col) all(is.na(col) | col == ""))) ){
    warning("calculate_abpm_metrics_for_period: bind_rows resulted in empty or all-NA dataframe (excluding MASKID).", call.=FALSE)
    MASKIDs <- if("MASKID" %in% colnames(wide_df)) wide_df$MASKID else character(0)
    # Return df with only MASKID if available
    return(results_df %>% select(any_of("MASKID")))
  }
  
  
  expected_cols_order <- c(
    "MASKID", "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV",
    "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
    "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
    "hyper_Burden", "hypo_Burden", "Se", "Sf"
    # Exclude n_over, n_total here as they are intermediate
  )
  
  present_cols <- intersect(expected_cols_order, colnames(results_df))
  results_df <- results_df %>% select(any_of(present_cols))
  
  return(results_df)
}


# --- 2.7b NEW Calculation Orchestrator for 24h Segmented ---
calculate_abpm_metrics_24h_segmented <- function(interpolated_dfs, sorted_times, sorted_minutes,
                                                 targets_day, targets_night, # Pass the lists of targets used
                                                 day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                 day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  
  metrics_to_calculate <- names(interpolated_dfs)
  final_results_list <- list()
  
  # Define Day/Night time boundaries (minutes) - Reuse logic from split_wide_data_day_night
  d1_day_start_min   <- day_start1_h * 60 + day_start1_m
  d1_night_start_min <- night_start1_h * 60 + night_start1_m
  d2_day_start_min   <- (24 * 60) + (day_start2_h * 60 + day_start2_m)
  d2_night_start_min <- (24 * 60) + (night_start2_h * 60 + night_start2_m)
  d0_night_end_min   <- d1_day_start_min
  d1_day_end_min     <- d1_night_start_min
  d1_night_end_min   <- d2_day_start_min
  d2_day_end_min     <- d2_night_start_min # End of Day 2 Day period
  
  # Helper to get limits from the passed target lists
  get_limits_from_passed <- function(metric_name, period_suffix, targets_list) {
    lower_name <- paste0(tolower(metric_name), "_", period_suffix, "_lower")
    upper_name <- paste0(tolower(metric_name), "_", period_suffix, "_upper")
    lower_val <- if(lower_name %in% names(targets_list)) targets_list[[lower_name]] else NA_real_
    upper_val <- if(upper_name %in% names(targets_list)) targets_list[[upper_name]] else NA_real_
    if (!is.numeric(lower_val)) lower_val <- NA_real_
    if (!is.numeric(upper_val)) upper_val <- NA_real_
    list(lower = lower_val, upper = upper_val)
  }
  
  # Helper function to safely sum potentially NA values, propagating NA if any component is NA
  sum_intermediate_na_aware <- function(day_val, night_val) {
    if (is.na(day_val) || is.na(night_val)) return(NA_real_)
    # Treat non-finite as 0 ONLY if both are finite or NA (to avoid issues if one is Inf)
    d <- if(!is.finite(day_val)) 0 else day_val
    n <- if(!is.finite(night_val)) 0 else night_val
    return(d + n)
  }
  # Simpler sum where NA can be treated as 0 (e.g., counts, times, Sd)
  sum_intermediate_na_as_zero <- function(day_val, night_val) {
    d <- if(is.na(day_val) || !is.finite(day_val)) 0 else day_val
    n <- if(is.na(night_val) || !is.finite(night_val)) 0 else night_val
    return(d + n)
  }
  
  for (metric in metrics_to_calculate) {
    wide_df <- interpolated_dfs[[metric]]
    if (is.null(wide_df) || !is.data.frame(wide_df) || nrow(wide_df) == 0) next
    
    limits_day <- get_limits_from_passed(metric, "day", targets_day)
    limits_night <- get_limits_from_passed(metric, "night", targets_night)
    
    # --- Validation: Skip metric if limits are fundamentally missing ---
    day_limits_incomplete <- is.na(limits_day$lower) || is.na(limits_day$upper)
    night_limits_incomplete <- is.na(limits_night$lower) || is.na(limits_night$upper)
    day_limits_fully_missing <- is.na(limits_day$lower) && is.na(limits_day$upper)
    night_limits_fully_missing <- is.na(limits_night$lower) && is.na(limits_night$upper)
    
    if (tolower(metric) %in% c("pp", "map") && day_limits_fully_missing && night_limits_fully_missing) {
      warning(paste("Skipping segmented 24h calculation for optional", metric, "due to missing limits in BOTH day and night periods."), call.=FALSE); next
    }
    if (tolower(metric) %in% c("sbp", "dbp", "hr") && (day_limits_incomplete || night_limits_incomplete)) {
      warning(paste("Skipping segmented 24h calculation for essential", metric, "due to incomplete day OR night limits."), call.=FALSE); next
    }
    # --- End Validation ---
    
    
    all_patient_results <- list()
    for (i in 1:nrow(wide_df)) {
      patient_id <- wide_df$MASKID[i]
      time_cols <- colnames(wide_df)[-1] # Should match sorted_times
      row_data <- suppressWarnings(as.numeric(unlist(wide_df[i, time_cols])))
      time_vals <- sorted_minutes # Use the full sorted minutes vector
      
      if(length(row_data) != length(time_vals)) {
        warning(paste("Segmented Calc: Patient", patient_id, "- Data/Time length mismatch. Skipping."), call.=FALSE); next
      }
      
      # --- Calculate Day/Night Separately, then Sum ---
      # 1. Filter data/time for Day periods
      day_indices <- which((time_vals >= d1_day_start_min & time_vals < d1_day_end_min) | (time_vals >= d2_day_start_min & time_vals < d2_day_end_min))
      day_data <- row_data[day_indices]; day_times <- time_vals[day_indices]
      
      # 2. Filter data/time for Night periods
      night_indices <- which((time_vals < d0_night_end_min) | (time_vals >= d1_night_start_min & time_vals < d1_night_end_min)) # Includes D0 and D1 night
      night_data <- row_data[night_indices]; night_times <- time_vals[night_indices]
      
      # 3. Calculate metrics for Day segment
      day_metrics <- list()
      if(length(day_data) >= 2 && length(day_times) == length(day_data)) {
        day_area_time <- calculate_areas_times_single_row(day_data, day_times, limits_day$upper, limits_day$lower)
        day_stats <- calculate_statistics_single_row(day_data, day_times, limits_day$upper) # Returns counts too
        day_metrics <- c(day_area_time, day_stats)
        day_metrics$Se <- if(is.finite(limits_day$upper) && is.finite(day_metrics$Ts1_total)) day_metrics$Ts1_total * limits_day$upper else NA_real_
        day_metrics$Sf <- if(is.finite(limits_day$lower) && is.finite(day_metrics$Ts3_total)) day_metrics$Ts3_total * limits_day$lower else NA_real_
      } else { # Handle cases with < 2 points
        day_metrics <- list(Sa=0, Sc=0, Sd=0, AUC=0, Ts1_total=0, Ts2_total=0, Ts3_total=0,
                            max_value=NA, min_value=NA, Delta=NA, mean=NA, SD=NA, CV=NA, ARV=NA, Load=NA,
                            n_over=0, n_total=sum(is.finite(day_data)), Se=NA_real_, Sf=NA_real_)
      }
      
      
      # 4. Calculate metrics for Night segment
      night_metrics <- list()
      if(length(night_data) >= 2 && length(night_times) == length(night_data)) {
        night_area_time <- calculate_areas_times_single_row(night_data, night_times, limits_night$upper, limits_night$lower)
        night_stats <- calculate_statistics_single_row(night_data, night_times, limits_night$upper) # Returns counts too
        night_metrics <- c(night_area_time, night_stats)
        night_metrics$Se <- if(is.finite(limits_night$upper) && is.finite(night_metrics$Ts1_total)) night_metrics$Ts1_total * limits_night$upper else NA_real_
        night_metrics$Sf <- if(is.finite(limits_night$lower) && is.finite(night_metrics$Ts3_total)) night_metrics$Ts3_total * limits_night$lower else NA_real_
      } else { # Handle cases with < 2 points
        night_metrics <- list(Sa=0, Sc=0, Sd=0, AUC=0, Ts1_total=0, Ts2_total=0, Ts3_total=0,
                              max_value=NA, min_value=NA, Delta=NA, mean=NA, SD=NA, CV=NA, ARV=NA, Load=NA,
                              n_over=0, n_total=sum(is.finite(night_data)), Se=NA_real_, Sf=NA_real_)
      }
      
      
      # 5. Sum intermediate results (using appropriate NA handling)
      Sa_sum <- sum_intermediate_na_aware(day_metrics$Sa, night_metrics$Sa) # NA if limits were NA
      Sc_sum <- sum_intermediate_na_aware(day_metrics$Sc, night_metrics$Sc) # NA if limits were NA
      Sd_sum <- sum_intermediate_na_as_zero(day_metrics$Sd, night_metrics$Sd) # AUC_sum = Sd_sum, always calculable
      Ts1_sum <- sum_intermediate_na_as_zero(day_metrics$Ts1_total, night_metrics$Ts1_total)
      Ts2_sum <- sum_intermediate_na_as_zero(day_metrics$Ts2_total, night_metrics$Ts2_total)
      Ts3_sum <- sum_intermediate_na_as_zero(day_metrics$Ts3_total, night_metrics$Ts3_total)
      n_over_sum <- sum_intermediate_na_as_zero(day_metrics$n_over, night_metrics$n_over) # Sum counts over respective limits
      n_total_sum <- sum_intermediate_na_as_zero(day_metrics$n_total, night_metrics$n_total) # Sum total valid points
      Se_sum <- sum_intermediate_na_aware(day_metrics$Se, night_metrics$Se) # NA if respective upper limits were NA
      Sf_sum <- sum_intermediate_na_aware(day_metrics$Sf, night_metrics$Sf) # NA if respective lower limits were NA
      
      
      # 6. Calculate combined ratios using summed values
      total_time_sum <- Ts1_sum + Ts2_sum + Ts3_sum
      ratios_combined <- list(
        Se = Se_sum, Sf = Sf_sum, # The combined Se/Sf
        TTR = NA_real_, TOTR = NA_real_, TUTR = NA_real_,
        hyper_Burden = NA_real_, hypo_Burden = NA_real_,
        cumulative_Load = NA_real_
      )
      
      if (is.finite(total_time_sum) && total_time_sum > 1e-9) {
        ratios_combined$TTR <- (Ts2_sum / total_time_sum) * 100
        ratios_combined$TOTR <- (Ts1_sum / total_time_sum) * 100
        ratios_combined$TUTR <- (Ts3_sum / total_time_sum) * 100
      } else if (is.finite(total_time_sum) && total_time_sum <= 1e-9) {
        ratios_combined$TTR <- 0; ratios_combined$TOTR <- 0; ratios_combined$TUTR <- 0;
      }
      
      # Hyper Burden (wTOR) - Requires Sa_sum, Se_sum, Ts1_sum, total_time_sum
      if(is.finite(Sa_sum) && is.finite(Se_sum) && is.finite(Ts1_sum) && is.finite(total_time_sum)) {
        denominator_wtor <- Sa_sum + Se_sum
        if (total_time_sum > 1e-9 && abs(denominator_wtor) > 1e-9) {
          ratios_combined$hyper_Burden <- (Sa_sum / denominator_wtor) * (Ts1_sum / total_time_sum) * 100
        } else if (total_time_sum > 1e-9 && abs(denominator_wtor) <= 1e-9 && abs(Sa_sum) < 1e-9) { # If Sa=0, Se=0 => Burden=0
          ratios_combined$hyper_Burden <- 0
        } else if (total_time_sum <= 1e-9) { # If total time is 0, burden is 0
          ratios_combined$hyper_Burden <- 0
        } # Implicitly NA otherwise
      } # Else hyper_Burden remains NA
      
      # Hypo Burden (wTUR) - Requires Sc_sum, Sf_sum, Ts3_sum, total_time_sum
      if(is.finite(Sc_sum) && is.finite(Sf_sum) && is.finite(Ts3_sum) && is.finite(total_time_sum)) {
        if (total_time_sum > 1e-9 && abs(Sf_sum) > 1e-9) {
          ratios_combined$hypo_Burden <- (Sc_sum / Sf_sum) * (Ts3_sum / total_time_sum) * 100
        } else if (total_time_sum > 1e-9 && abs(Sf_sum) <= 1e-9 && abs(Sc_sum) < 1e-9) { # If Sc=0, Sf=0 => Burden=0
          ratios_combined$hypo_Burden <- 0
        } else if (total_time_sum <= 1e-9) { # If total time is 0, burden is 0
          ratios_combined$hypo_Burden <- 0
        } # Implicitly NA otherwise
      } # Else hypo_Burden remains NA
      
      # Cumulative Load - Requires Sa_sum, Sd_sum
      if (is.finite(Sa_sum) && is.finite(Sd_sum)) {
        if (abs(Sd_sum) > 1e-9) { # Requires non-zero total area (Sd/AUC)
          ratios_combined$cumulative_Load <- Sa_sum / Sd_sum * 100
        } else if (abs(Sa_sum) < 1e-9) { # If Sa is 0 and Sd is 0, load is 0
          ratios_combined$cumulative_Load <- 0
        } # Implicitly NA otherwise
      } # Else cumulative_Load remains NA
      
      
      # 7. Calculate combined stats (Mean, SD, ARV, Max, Min, Delta, Load)
      # Load is based on summed counts
      load_final_combined <- if (n_total_sum > 0) (n_over_sum / n_total_sum) * 100 else NA_real_
      
      # Recalculate other overall stats (Mean, SD, CV, ARV, Max, Min, Delta) using the full 24h data
      valid_full_data <- row_data[is.finite(row_data)]
      n_valid_overall <- length(valid_full_data)
      
      mean_overall <- if(n_valid_overall > 0) mean(valid_full_data) else NA_real_
      sd_overall <- if(n_valid_overall > 1) sd(valid_full_data) else if (n_valid_overall == 1) 0 else NA_real_
      cv_overall <- if (!is.na(mean_overall) && abs(mean_overall) > 1e-9 && !is.na(sd_overall)) (sd_overall / abs(mean_overall)) * 100 else NA_real_
      arv_overall <- NA_real_
      if(n_valid_overall > 1) {
        arv_overall_calc <- mean(abs(diff(valid_full_data)), na.rm = TRUE)
        if(is.finite(arv_overall_calc)) arv_overall <- arv_overall_calc
      }
      max_overall <- if(n_valid_overall > 0) max(valid_full_data) else NA_real_
      min_overall <- if(n_valid_overall > 0) min(valid_full_data) else NA_real_
      delta_overall <- if(is.finite(max_overall) && is.finite(min_overall)) max_overall - min_overall else NA_real_
      
      stats_combined <- list(
        max_value = max_overall, min_value = min_overall, Delta = delta_overall,
        mean = mean_overall, SD = sd_overall, CV = cv_overall, ARV = arv_overall,
        Load = load_final_combined # Use the Load calculated from summed counts
      )
      
      # 8. Combine all results for the patient
      patient_results <- c(
        list(MASKID = patient_id),
        stats_combined, # Max, Min, Delta, Mean, SD, CV, ARV, Load
        list(Sa = Sa_sum, Sc = Sc_sum, Sd = Sd_sum, AUC = Sd_sum, # Summed areas
             Ts1_total = Ts1_sum, Ts2_total = Ts2_sum, Ts3_total = Ts3_sum), # Summed times
        ratios_combined # TTR, TOTR, TUTR, hyper/hypo Burden, Cum Load, Se, Sf
      )
      all_patient_results[[i]] <- patient_results
      
    } # End loop through patients (i)
    
    # Combine results into a dataframe
    if (length(all_patient_results) > 0) {
      results_df_metric <- bind_rows(all_patient_results)
      
      # Reorder columns to match the other function's output
      expected_cols_order_seg <- c(
        "MASKID", "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV",
        "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
        "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
        "hyper_Burden", "hypo_Burden", "Se", "Sf"
      )
      # Select present columns and reorder
      present_cols_seg <- intersect(expected_cols_order_seg, colnames(results_df_metric))
      results_df_metric <- results_df_metric %>% select(any_of(present_cols_seg))
      
      # Rename columns with metric prefix
      cols_to_rename <- setdiff(colnames(results_df_metric), "MASKID")
      colnames(results_df_metric)[colnames(results_df_metric) %in% cols_to_rename] <- paste0(metric, "_", cols_to_rename)
      final_results_list[[metric]] <- results_df_metric
    } else {
      warning(paste("Segmented 24h calculation yielded no results for metric", metric), call.=FALSE)
    }
    
  } # End loop through metrics
  
  return(final_results_list)
}


# --- 2.7c Patient-specific calculation pipeline (batch-invariant interpolation) ---
# Existing metric formulae above are intentionally retained.  This layer only
# separates the data source: traditional statistics use observed readings,
# whereas time/area metrics use a patient-specific interpolated time axis.
create_individual_patient_series <- function(long_data,
                                             day_start1_h, day_start1_m,
                                             night_start1_h, night_start1_m,
                                             day_start2_h, day_start2_m,
                                             night_start2_h, night_start2_m) {
  boundary_minutes <- c(
    day_start1_h * 60 + day_start1_m,
    night_start1_h * 60 + night_start1_m,
    24 * 60 + day_start2_h * 60 + day_start2_m,
    24 * 60 + night_start2_h * 60 + night_start2_m
  )
  metrics <- intersect(c("SBP", "DBP", "HR", "PP", "MAP"), names(long_data))
  output <- list()

  for (metric in metrics) {
    metric_patients <- list()
    patient_ids <- sort(unique(as.character(long_data$MASKID)))
    for (patient_id in patient_ids) {
      # Keep every observed row for Mean/SD/CV/ARV/VIM/Max/Min/Delta and
      # count-based Load. Duplicate timestamps are real observations and must
      # not be collapsed for these traditional statistics.
      raw <- long_data %>%
        filter(MASKID == patient_id, is.finite(Total_Minutes), is.finite(.data[[metric]])) %>%
        transmute(MASKID = as.character(MASKID),
                  Time = as.character(Time),
                  Total_Minutes = as.numeric(Total_Minutes),
                  Value = as.numeric(.data[[metric]]),
                  .source_order = dplyr::row_number()) %>%
        arrange(Total_Minutes, .source_order) %>%
        select(-.source_order)

      if (nrow(raw) == 0) next

      # Interpolation requires a unique x-axis. Only this interpolation source
      # averages duplicate timestamps; the raw observations above stay intact.
      interpolation_source <- raw %>%
        group_by(Total_Minutes) %>%
        summarise(Value = mean(Value), .groups = "drop") %>%
        arrange(Total_Minutes)

      raw <- raw %>% select(MASKID, Time, Total_Minutes, Value)

      min_time <- min(interpolation_source$Total_Minutes)
      max_time <- max(interpolation_source$Total_Minutes)
      internal_boundaries <- boundary_minutes[boundary_minutes >= min_time & boundary_minutes <= max_time]
      patient_axis <- sort(unique(c(interpolation_source$Total_Minutes, internal_boundaries)))

      if (nrow(interpolation_source) >= 2) {
        interpolated_values <- approx(
          x = interpolation_source$Total_Minutes,
          y = interpolation_source$Value,
          xout = patient_axis,
          method = "linear",
          rule = 1,
          ties = "ordered"
        )$y
      } else {
        interpolated_values <- rep(NA_real_, length(patient_axis))
        interpolated_values[match(interpolation_source$Total_Minutes, patient_axis)] <- interpolation_source$Value
      }

      interpolated <- data.frame(
        MASKID = patient_id,
        Time = vapply(patient_axis, minutes_to_time_string, character(1)),
        Total_Minutes = patient_axis,
        Value = interpolated_values,
        Is_Observed = patient_axis %in% interpolation_source$Total_Minutes,
        stringsAsFactors = FALSE
      ) %>% filter(is.finite(Value))

      metric_patients[[patient_id]] <- list(raw = raw, interpolated = interpolated)
    }
    if (length(metric_patients) > 0) output[[metric]] <- metric_patients
  }
  output
}

individual_series_to_wide <- function(individual_series) {
  all_minutes <- sort(unique(unlist(lapply(individual_series, function(metric_series) {
    unlist(lapply(metric_series, function(patient_series) patient_series$interpolated$Total_Minutes))
  }))))
  if (length(all_minutes) == 0) {
    return(list(wide_dfs = list(), sorted_times = character(0), sorted_minutes = numeric(0)))
  }
  all_times <- vapply(all_minutes, minutes_to_time_string, character(1))
  names(all_minutes) <- all_times
  wide_dfs <- list()

  for (metric in names(individual_series)) {
    long_metric <- bind_rows(lapply(individual_series[[metric]], function(patient_series) {
      patient_series$interpolated %>% select(MASKID, Time, Value)
    }))
    if (nrow(long_metric) == 0) next
    wide <- long_metric %>%
      pivot_wider(id_cols = MASKID, names_from = Time, values_from = Value,
                  values_fn = function(x) mean(x, na.rm = TRUE))
    for (time_name in setdiff(all_times, names(wide))) wide[[time_name]] <- NA_real_
    wide_dfs[[metric]] <- wide %>% select(MASKID, all_of(all_times))
  }
  list(wide_dfs = wide_dfs, sorted_times = all_times, sorted_minutes = all_minutes)
}

individual_period_indices <- function(time_values, period_key,
                                      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                      day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  d1_day_start <- day_start1_h * 60 + day_start1_m
  d1_night_start <- night_start1_h * 60 + night_start1_m
  d2_day_start <- 24 * 60 + day_start2_h * 60 + day_start2_m
  d2_night_start <- 24 * 60 + night_start2_h * 60 + night_start2_m
  if (period_key == "24h") return(seq_along(time_values))
  if (period_key == "day") {
    return(which((time_values >= d1_day_start & time_values < d1_night_start) |
                   (time_values >= d2_day_start & time_values < d2_night_start)))
  }
  if (period_key == "night") {
    return(which(time_values < d1_day_start |
                   (time_values >= d1_night_start & time_values < d2_day_start)))
  }
  integer(0)
}

add_vim_from_observed_results <- function(results_df) {
  results_df$VIM <- NA_real_
  if (!all(c("mean", "SD") %in% names(results_df))) return(results_df)
  valid <- is.finite(results_df$mean) & results_df$mean > 0 &
    is.finite(results_df$SD) & results_df$SD > 0
  if (sum(valid) < 2 || length(unique(results_df$mean[valid])) < 2) return(results_df)
  fit <- tryCatch(lm(log(SD) ~ log(mean), data = results_df[valid, , drop = FALSE]),
                  error = function(e) NULL)
  if (is.null(fit)) return(results_df)
  beta <- suppressWarnings(as.numeric(coef(fit)[2]))
  cohort_mean <- mean(results_df$mean[valid])
  if (!is.finite(beta) || !is.finite(cohort_mean) || cohort_mean <= 0) return(results_df)
  results_df$VIM[valid] <- results_df$SD[valid] /
    (results_df$mean[valid] ^ beta) * (cohort_mean ^ beta)
  results_df
}

calculate_abpm_metrics_for_period_individual <- function(metric_patient_series, period_key,
                                                         upper_limit, lower_limit,
                                                         day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                         day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  all_results <- list()
  for (patient_id in names(metric_patient_series)) {
    patient_series <- metric_patient_series[[patient_id]]
    interp <- patient_series$interpolated %>% arrange(Total_Minutes)
    raw <- patient_series$raw %>% arrange(Total_Minutes)
    interp_idx <- individual_period_indices(
      interp$Total_Minutes, period_key,
      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
      day_start2_h, day_start2_m, night_start2_h, night_start2_m
    )
    raw_idx <- individual_period_indices(
      raw$Total_Minutes, period_key,
      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
      day_start2_h, day_start2_m, night_start2_h, night_start2_m
    )

    area_time_res <- calculate_areas_times_single_row(
      interp$Value[interp_idx], interp$Total_Minutes[interp_idx], upper_limit, lower_limit
    )
    stats_res_full <- calculate_statistics_single_row(
      raw$Value[raw_idx], raw$Total_Minutes[raw_idx], upper_limit
    )
    stats_res <- stats_res_full[c("max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "Load")]
    ratio_res <- calculate_ratios_single_row(area_time_res, upper_limit, lower_limit)
    all_results[[patient_id]] <- c(list(MASKID = patient_id), area_time_res, stats_res, ratio_res)
  }
  if (length(all_results) == 0) return(data.frame(MASKID = character(0)))
  results_df <- bind_rows(all_results)
  results_df <- add_vim_from_observed_results(results_df)
  expected <- c(
    "MASKID", "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
    "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
    "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
    "hyper_Burden", "hypo_Burden", "Se", "Sf"
  )
  results_df %>% select(any_of(expected))
}

# Optional PP/MAP may intentionally have no target range. In that case retain
# every result that does not require a threshold: observed-value statistics and
# the patient-specific interpolated total AUC. Threshold-dependent fields stay
# NA instead of being misreported as a 100% TTR.
calculate_abpm_metrics_without_limits_individual <- function(metric_patient_series, period_key,
                                                              day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                              day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  all_results <- list()
  for (patient_id in names(metric_patient_series)) {
    patient_series <- metric_patient_series[[patient_id]]
    interp <- patient_series$interpolated %>% arrange(Total_Minutes)
    raw <- patient_series$raw %>% arrange(Total_Minutes)
    interp_idx <- individual_period_indices(
      interp$Total_Minutes, period_key,
      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
      day_start2_h, day_start2_m, night_start2_h, night_start2_m
    )
    raw_idx <- individual_period_indices(
      raw$Total_Minutes, period_key,
      day_start1_h, day_start1_m, night_start1_h, night_start1_m,
      day_start2_h, day_start2_m, night_start2_h, night_start2_m
    )

    auc_res <- calculate_areas_times_single_row(
      interp$Value[interp_idx], interp$Total_Minutes[interp_idx], NA_real_, NA_real_
    )
    stats_full <- calculate_statistics_single_row(
      raw$Value[raw_idx], raw$Total_Minutes[raw_idx], NA_real_
    )
    all_results[[patient_id]] <- list(
      MASKID = patient_id,
      max_value = stats_full$max_value, min_value = stats_full$min_value,
      Delta = stats_full$Delta, mean = stats_full$mean, SD = stats_full$SD,
      CV = stats_full$CV, ARV = stats_full$ARV,
      Sa = NA_real_, Sc = NA_real_, Sd = auc_res$Sd, AUC = auc_res$AUC,
      Ts1_total = NA_real_, Ts2_total = NA_real_, Ts3_total = NA_real_,
      Load = NA_real_, cumulative_Load = NA_real_,
      TTR = NA_real_, TOTR = NA_real_, TUTR = NA_real_,
      hyper_Burden = NA_real_, hypo_Burden = NA_real_,
      Se = NA_real_, Sf = NA_real_
    )
  }
  if (length(all_results) == 0) return(data.frame(MASKID = character(0)))
  results_df <- add_vim_from_observed_results(bind_rows(all_results))
  expected <- c(
    "MASKID", "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
    "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
    "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
    "hyper_Burden", "hypo_Burden", "Se", "Sf"
  )
  results_df %>% select(any_of(expected))
}

calculate_abpm_metrics_24h_segmented_individual <- function(individual_series,
                                                            targets_day, targets_night,
                                                            day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                                            day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  get_limits <- function(metric, suffix, target_list) {
    lower_name <- paste0(tolower(metric), "_", suffix, "_lower")
    upper_name <- paste0(tolower(metric), "_", suffix, "_upper")
    list(
      lower = if (lower_name %in% names(target_list)) as.numeric(target_list[[lower_name]]) else NA_real_,
      upper = if (upper_name %in% names(target_list)) as.numeric(target_list[[upper_name]]) else NA_real_
    )
  }
  sum_zero <- function(...) sum(c(...)[is.finite(c(...))], na.rm = TRUE)
  sum_aware <- function(a, b) if (is.finite(a) && is.finite(b)) a + b else NA_real_
  zero_area <- list(Sa = 0, Sc = 0, Sd = 0, AUC = 0,
                    Ts1_total = 0, Ts2_total = 0, Ts3_total = 0)
  final_results <- list()

  for (metric in names(individual_series)) {
    day_limits <- get_limits(metric, "day", targets_day)
    night_limits <- get_limits(metric, "night", targets_night)
    if (tolower(metric) %in% c("pp", "map") &&
        any(is.na(c(day_limits$lower, day_limits$upper, night_limits$lower, night_limits$upper)))) {
      results_df <- calculate_abpm_metrics_without_limits_individual(
        individual_series[[metric]], "24h",
        day_start1_h, day_start1_m, night_start1_h, night_start1_m,
        day_start2_h, day_start2_m, night_start2_h, night_start2_m
      )
      if (nrow(results_df) > 0) {
        names(results_df)[names(results_df) != "MASKID"] <- paste0(metric, "_", names(results_df)[names(results_df) != "MASKID"])
        final_results[[metric]] <- results_df
      }
      next
    }
    if (tolower(metric) %in% c("sbp", "dbp", "hr") &&
        any(is.na(c(day_limits$lower, day_limits$upper, night_limits$lower, night_limits$upper)))) next

    patient_results <- list()
    for (patient_id in names(individual_series[[metric]])) {
      patient_series <- individual_series[[metric]][[patient_id]]
      interp <- patient_series$interpolated %>% arrange(Total_Minutes)
      raw <- patient_series$raw %>% arrange(Total_Minutes)
      day_i <- individual_period_indices(interp$Total_Minutes, "day",
                                         day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                         day_start2_h, day_start2_m, night_start2_h, night_start2_m)
      night_i <- individual_period_indices(interp$Total_Minutes, "night",
                                           day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                           day_start2_h, day_start2_m, night_start2_h, night_start2_m)
      day_r <- individual_period_indices(raw$Total_Minutes, "day",
                                         day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                         day_start2_h, day_start2_m, night_start2_h, night_start2_m)
      night_r <- individual_period_indices(raw$Total_Minutes, "night",
                                           day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                           day_start2_h, day_start2_m, night_start2_h, night_start2_m)

      day_area <- if (length(day_i) >= 2) {
        calculate_areas_times_single_row(interp$Value[day_i], interp$Total_Minutes[day_i],
                                         day_limits$upper, day_limits$lower)
      } else zero_area
      night_area <- if (length(night_i) >= 2) {
        calculate_areas_times_single_row(interp$Value[night_i], interp$Total_Minutes[night_i],
                                         night_limits$upper, night_limits$lower)
      } else zero_area
      day_stats <- calculate_statistics_single_row(raw$Value[day_r], raw$Total_Minutes[day_r], day_limits$upper)
      night_stats <- calculate_statistics_single_row(raw$Value[night_r], raw$Total_Minutes[night_r], night_limits$upper)

      Sa <- sum_aware(day_area$Sa, night_area$Sa)
      Sc <- sum_aware(day_area$Sc, night_area$Sc)
      Sd <- sum_zero(day_area$Sd, night_area$Sd)
      Ts1 <- sum_zero(day_area$Ts1_total, night_area$Ts1_total)
      Ts2 <- sum_zero(day_area$Ts2_total, night_area$Ts2_total)
      Ts3 <- sum_zero(day_area$Ts3_total, night_area$Ts3_total)
      total_time <- Ts1 + Ts2 + Ts3
      Se <- sum_aware(Ts1 * 0 + day_area$Ts1_total * day_limits$upper,
                      night_area$Ts1_total * night_limits$upper)
      Sf <- sum_aware(day_area$Ts3_total * day_limits$lower,
                      night_area$Ts3_total * night_limits$lower)

      TTR <- if (total_time > 1e-9) Ts2 / total_time * 100 else 0
      TOTR <- if (total_time > 1e-9) Ts1 / total_time * 100 else 0
      TUTR <- if (total_time > 1e-9) Ts3 / total_time * 100 else 0
      hyper_burden <- NA_real_
      if (is.finite(Sa) && is.finite(Se)) {
        denom <- Sa + Se
        hyper_burden <- if (total_time <= 1e-9) 0 else if (abs(denom) > 1e-9) (Sa / denom) * (Ts1 / total_time) * 100 else 0
      }
      hypo_burden <- NA_real_
      if (is.finite(Sc) && is.finite(Sf)) {
        hypo_burden <- if (total_time <= 1e-9) 0 else if (abs(Sf) > 1e-9) (Sc / Sf) * (Ts3 / total_time) * 100 else 0
      }
      cumulative_load <- if (is.finite(Sa) && is.finite(Sd)) {
        if (abs(Sd) > 1e-9) Sa / Sd * 100 else if (abs(Sa) < 1e-9) 0 else NA_real_
      } else NA_real_

      raw_full_stats <- calculate_statistics_single_row(raw$Value, raw$Total_Minutes, NA_real_)
      n_over <- sum_zero(day_stats$n_over, night_stats$n_over)
      n_total <- sum_zero(day_stats$n_total, night_stats$n_total)
      raw_load <- if (n_total > 0) n_over / n_total * 100 else NA_real_

      patient_results[[patient_id]] <- list(
        MASKID = patient_id,
        max_value = raw_full_stats$max_value, min_value = raw_full_stats$min_value,
        Delta = raw_full_stats$Delta, mean = raw_full_stats$mean, SD = raw_full_stats$SD,
        CV = raw_full_stats$CV, ARV = raw_full_stats$ARV,
        Sa = Sa, Sc = Sc, Sd = Sd, AUC = Sd,
        Ts1_total = Ts1, Ts2_total = Ts2, Ts3_total = Ts3,
        Load = raw_load, cumulative_Load = cumulative_load,
        TTR = TTR, TOTR = TOTR, TUTR = TUTR,
        hyper_Burden = hyper_burden, hypo_Burden = hypo_burden,
        Se = Se, Sf = Sf
      )
    }
    if (length(patient_results) == 0) next
    result_df <- add_vim_from_observed_results(bind_rows(patient_results))
    expected <- c(
      "MASKID", "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
      "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
      "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
      "hyper_Burden", "hypo_Burden", "Se", "Sf"
    )
    result_df <- result_df %>% select(any_of(expected))
    names(result_df)[names(result_df) != "MASKID"] <- paste0(metric, "_", names(result_df)[names(result_df) != "MASKID"])
    final_results[[metric]] <- result_df
  }
  final_results
}


# --- 2.8 Visualization Plotting Functions --- (Unchanged)

# Add formatted hover text after ggplotly conversion. This keeps the original
# tooltip content without passing the plotly-only `text` aesthetic to ggplot2.
apply_point_hover_text <- function(plotly_object, hover_text) {
  if (is.null(plotly_object$x$data) || length(hover_text) == 0) return(plotly_object)
  for (trace_index in seq_along(plotly_object$x$data)) {
    trace <- plotly_object$x$data[[trace_index]]
    is_marker_trace <- !is.null(trace$mode) && grepl("markers", trace$mode, fixed = TRUE)
    if (is_marker_trace && length(trace$x) == length(hover_text)) {
      plotly_object$x$data[[trace_index]]$text <- hover_text
      plotly_object$x$data[[trace_index]]$hoverinfo <- "text"
      plotly_object$x$data[[trace_index]]$hovertemplate <- "%{text}<extra></extra>"
    }
  }
  plotly_object
}

# --- 2.8.1 Generic Trend Chart (Day/Night/24h_Single_Limit, with background) ---
create_metric_trend_chart <- function(bp_data, sorted_times, sorted_minutes, maskid_selected, metric_name, upper_limit, lower_limit) {
  # Input Validation
  req(bp_data, sorted_times, sorted_minutes, maskid_selected, metric_name)
  if (!"MASKID" %in% colnames(bp_data)) {
    return(plot_ly() %>% layout(title = "数据错误: 缺少 MASKID 列", xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  if (length(sorted_times) != length(sorted_minutes)) {
    return(plot_ly() %>% layout(title = "内部错误: 时间向量不匹配", xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  bp_data$MASKID <- as.character(bp_data$MASKID)
  maskid_selected_char <- as.character(maskid_selected)
  
  # Filter data for the selected MASKID
  selected_data_row <- bp_data[bp_data$MASKID == maskid_selected_char, , drop = FALSE]
  if (nrow(selected_data_row) == 0) {
    return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的数据 (指标: ", metric_name, ")"), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  
  # Extract values and align with time points
  time_cols <- setdiff(colnames(selected_data_row), "MASKID")
  time_cols_in_order <- intersect(sorted_times, time_cols)
  if (length(time_cols_in_order) == 0) {
    return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的有效时间列 (指标: ", metric_name, ")"), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  plot_values_raw <- unlist(selected_data_row[1, time_cols_in_order], use.names = FALSE)
  plot_values <- suppressWarnings(as.numeric(plot_values_raw))
  time_match_indices <- match(time_cols_in_order, sorted_times)
  plot_minutes <- sorted_minutes[time_match_indices]
  plot_times_formatted_original <- sapply(plot_minutes, minutes_to_formatted_string) # Keep for tooltips
  
  # Combine into a plotting dataframe
  plot_data <- data.frame(
    TimeValue = plot_minutes,
    Value = plot_values,
    TimeLabelHover = plot_times_formatted_original, # Use this for hover text
    stringsAsFactors = FALSE
  ) %>% filter(is.finite(Value) & is.finite(TimeValue)) %>%
    arrange(TimeValue)
  
  if (nrow(plot_data) == 0) {
    return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的有效数据点 (指标: ", metric_name, ")"), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  
  # --- Dynamic Y-axis Range Calculation ---
  valid_upper <- is.numeric(upper_limit) && is.finite(upper_limit)
  valid_lower <- is.numeric(lower_limit) && is.finite(lower_limit)
  y_vals_for_range <- plot_data$Value
  if(valid_upper) y_vals_for_range <- c(y_vals_for_range, upper_limit)
  if(valid_lower) y_vals_for_range <- c(y_vals_for_range, lower_limit)
  min_y <- min(y_vals_for_range, na.rm = TRUE)
  max_y <- max(y_vals_for_range, na.rm = TRUE)
  y_range_padding <- max(5, (max_y - min_y) * 0.15)
  y_axis_limits <- c(min_y - y_range_padding, max_y + y_range_padding)
  if(!is.finite(y_axis_limits[1])) y_axis_limits[1] <- 0
  if(!is.finite(y_axis_limits[2])) y_axis_limits[2] <- y_axis_limits[1] + 10
  if(y_axis_limits[2] <= y_axis_limits[1]) y_axis_limits[2] <- y_axis_limits[1] + 10
  
  # --- Calculate Hourly Breaks and Labels ---
  min_time_val <- min(plot_data$TimeValue, na.rm = TRUE)
  max_time_val <- max(plot_data$TimeValue, na.rm = TRUE)
  
  hourly_minute_breaks <- numeric(0); hourly_labels <- character(0)
  if(is.finite(min_time_val) && is.finite(max_time_val) && max_time_val >= min_time_val) {
    first_hour_min <- floor(min_time_val / 60) * 60
    last_hour_min <- ceiling(max_time_val / 60) * 60
    if (last_hour_min >= first_hour_min) {
      hourly_minute_breaks <- seq(from = first_hour_min, to = last_hour_min, by = 60)
      # Prevent labels from overlapping too much
      label_density_factor <- max(1, floor(length(hourly_minute_breaks) / 15))
      breaks_to_label <- seq(1, length(hourly_minute_breaks), by = label_density_factor)
      hourly_labels <- rep("", length(hourly_minute_breaks))
      hourly_labels[breaks_to_label] <- sapply(hourly_minute_breaks[breaks_to_label], minutes_to_formatted_string)
    }
  }
  if(length(hourly_minute_breaks) == 0 && nrow(plot_data) > 0) {
    warning("Could not generate hourly breaks for trend chart, falling back to data points.", call. = FALSE)
    hourly_minute_breaks <- plot_data$TimeValue
    hourly_labels <- plot_data$TimeLabelHover
  } else if (length(hourly_minute_breaks) == 0) {
    return(plot_ly() %>% layout(title = paste("无有效数据点用于生成趋势图 - MASKID:", maskid_selected_char, "- 指标:", metric_name), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
  }
  
  # --- Create ggplot object ---
  p <- ggplot(plot_data, aes(x = TimeValue, y = Value)) +
    
    # --- Background Shading ---
    # Uses the provided upper/lower limits for the entire period
    { if(valid_lower && valid_upper && is.finite(min_time_val) && is.finite(max_time_val) && max_time_val > min_time_val)
      annotate("rect", xmin = min_time_val, xmax = max_time_val, ymin = lower_limit, ymax = upper_limit,
               fill = "#A5D6A7", alpha = 0.3) } +
    
    # --- Data Line and Points ---
    { if(nrow(plot_data) > 1) geom_line(color = "black", linewidth = 0.8, aes(group = 1)) } +
    geom_point(color = "black", size = 2.5) +
    
    # --- Limit Lines (hline) ---
    { if(valid_upper) geom_hline(yintercept = upper_limit, linetype = "dashed", color = "red", linewidth = 0.8) } +
    { if(valid_lower) geom_hline(yintercept = lower_limit, linetype = "dashed", color = "blue", linewidth = 0.8) } +
    
    # --- Scales and Theme ---
    scale_y_continuous(limits = y_axis_limits, n.breaks = 6) +
    scale_x_continuous(breaks = hourly_minute_breaks, labels = hourly_labels) +
    labs(title = NULL, x = "时间点", y = paste(metric_name, "值")) + # Simpler X axis title
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_blank(),
      axis.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size=rel(0.9)), # Adjusted angle/size
      legend.position = "none",
      panel.grid.minor = element_blank()
    )
  
  # --- Convert to Plotly and Add Annotations ---
  hover_text <- paste("时间:", plot_data$TimeLabelHover, "<br>", metric_name, ":", round(plot_data$Value, 1))
  p_plotly <- ggplotly(p, tooltip = c("x", "y"))
  p_plotly <- apply_point_hover_text(p_plotly, hover_text)
  
  max_time_value_for_anno <- max(plot_data$TimeValue, na.rm = TRUE)
  if(!is.finite(max_time_value_for_anno) && length(hourly_minute_breaks) > 0) {
    max_time_value_for_anno <- max(hourly_minute_breaks)
  } else if (!is.finite(max_time_value_for_anno)) {
    max_time_value_for_anno <- 0
  }
  
  annotations_list <- list()
  if(valid_upper) {
    annotations_list <- c(annotations_list, list(
      list(
        x = max_time_value_for_anno, y = upper_limit, text = paste("上限:", upper_limit),
        showarrow = FALSE, xref = "x", yref = "y", yshift = 10, xanchor = 'right',
        font = list(color = "red", size = 10)
      )
    ))
  }
  if(valid_lower) {
    annotations_list <- c(annotations_list, list(
      list(
        x = max_time_value_for_anno, y = lower_limit, text = paste("下限:", lower_limit),
        showarrow = FALSE, xref = "x", yref = "y", yshift = -10, xanchor = 'right',
        font = list(color = "blue", size = 10)
      )
    ))
  }
  
  # Title will be set in the server call for better context
  p_plotly <- p_plotly %>% layout(
    # Title added in server call
    annotations = annotations_list,
    margin = list(l = 60, r = 80, t = 50, b = 100) # Adjusted bottom margin for angled labels
  )
  
  return(p_plotly)
}

# --- 2.8.2 Trend Chart for 24h (Handles Day/Night Segmented Limits & Shading) ---
create_metric_trend_chart_24h <- function(bp_data, sorted_times, sorted_minutes, maskid_selected, metric_name,
                                          day_upper_limit, day_lower_limit,
                                          night_upper_limit, night_lower_limit,
                                          day_start1_h, day_start1_m, night_start1_h, night_start1_m,
                                          day_start2_h, day_start2_m, night_start2_h, night_start2_m) {
  
  # --- Basic Input Validation ---
  req(bp_data, sorted_times, sorted_minutes, maskid_selected, metric_name)
  if (!"MASKID" %in% colnames(bp_data)) { return(plot_ly() %>% layout(title = "数据错误: 缺少 MASKID 列")) }
  if (length(sorted_times) != length(sorted_minutes)) { return(plot_ly() %>% layout(title = "内部错误: 时间向量不匹配")) }
  bp_data$MASKID <- as.character(bp_data$MASKID)
  maskid_selected_char <- as.character(maskid_selected)
  
  # --- Filter data ---
  selected_data_row <- bp_data[bp_data$MASKID == maskid_selected_char, , drop = FALSE]
  if (nrow(selected_data_row) == 0) { return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的数据"))) }
  
  # --- Extract values ---
  time_cols <- setdiff(colnames(selected_data_row), "MASKID")
  time_cols_in_order <- intersect(sorted_times, time_cols)
  if (length(time_cols_in_order) == 0) { return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的有效时间列"))) }
  plot_values_raw <- unlist(selected_data_row[1, time_cols_in_order], use.names = FALSE)
  plot_values <- suppressWarnings(as.numeric(plot_values_raw))
  time_match_indices <- match(time_cols_in_order, sorted_times)
  plot_minutes <- sorted_minutes[time_match_indices]
  plot_times_formatted_original <- sapply(plot_minutes, minutes_to_formatted_string)
  
  # --- Combine into a plotting dataframe ---
  plot_data <- data.frame(
    TimeValue = plot_minutes,
    Value = plot_values,
    TimeLabelHover = plot_times_formatted_original,
    stringsAsFactors = FALSE
  ) %>% filter(is.finite(Value) & is.finite(TimeValue)) %>%
    arrange(TimeValue)
  
  if (nrow(plot_data) == 0) { return(plot_ly() %>% layout(title = paste("未找到 MASKID:", maskid_selected_char, "的有效数据点"))) }
  
  # --- Define Day/Night Time Boundaries in Minutes ---
  d1_day_start_min   <- as.integer(day_start1_h) * 60 + as.integer(day_start1_m)
  d1_night_start_min <- as.integer(night_start1_h) * 60 + as.integer(night_start1_m)
  d2_day_start_min   <- (24 * 60) + (as.integer(day_start2_h) * 60 + as.integer(day_start2_m))
  d2_night_start_min <- (24 * 60) + (as.integer(night_start2_h) * 60 + as.integer(night_start2_m))
  
  d0_night_end_min <- d1_day_start_min
  d1_day_end_min   <- d1_night_start_min
  d1_night_end_min <- d2_day_start_min
  d2_day_end_min   <- d2_night_start_min # Theoretical end if D2 night exists
  
  min_time_val <- min(plot_data$TimeValue, na.rm = TRUE)
  max_time_val <- max(plot_data$TimeValue, na.rm = TRUE)
  d0_night_start_min <- if(is.finite(min_time_val) && min_time_val < d1_day_start_min) min_time_val else d1_day_start_min
  # Adjust calculation for d2_day_actual_end_min to ensure it covers the last point even if it falls into the theoretical D2 night start
  d2_day_actual_end_min <- if(is.finite(max_time_val)) max_time_val else d2_day_end_min
  
  # --- Validate Limits ---
  valid_day_upper <- is.numeric(day_upper_limit) && is.finite(day_upper_limit)
  valid_day_lower <- is.numeric(day_lower_limit) && is.finite(day_lower_limit)
  valid_night_upper <- is.numeric(night_upper_limit) && is.finite(night_upper_limit)
  valid_night_lower <- is.numeric(night_lower_limit) && is.finite(night_lower_limit)
  
  # --- Dynamic Y-axis Range Calculation ---
  y_vals_for_range <- plot_data$Value
  if(valid_day_upper) y_vals_for_range <- c(y_vals_for_range, day_upper_limit)
  if(valid_day_lower) y_vals_for_range <- c(y_vals_for_range, day_lower_limit)
  if(valid_night_upper) y_vals_for_range <- c(y_vals_for_range, night_upper_limit)
  if(valid_night_lower) y_vals_for_range <- c(y_vals_for_range, night_lower_limit)
  min_y <- min(y_vals_for_range, na.rm = TRUE)
  max_y <- max(y_vals_for_range, na.rm = TRUE)
  y_range_padding <- max(5, (max_y - min_y) * 0.15)
  y_axis_limits <- c(min_y - y_range_padding, max_y + y_range_padding)
  if(!is.finite(y_axis_limits[1])) y_axis_limits[1] <- 0
  if(!is.finite(y_axis_limits[2])) y_axis_limits[2] <- y_axis_limits[1] + 10
  if(y_axis_limits[2] <= y_axis_limits[1]) y_axis_limits[2] <- y_axis_limits[1] + 10
  
  # --- Calculate Hourly Breaks and Labels ---
  hourly_minute_breaks <- numeric(0); hourly_labels <- character(0)
  if(is.finite(min_time_val) && is.finite(max_time_val) && max_time_val >= min_time_val) {
    first_hour_min <- floor(min_time_val / 60) * 60
    last_hour_min <- ceiling(max_time_val / 60) * 60
    if (last_hour_min >= first_hour_min) {
      hourly_minute_breaks <- seq(from = first_hour_min, to = last_hour_min, by = 60)
      label_density_factor <- max(1, floor(length(hourly_minute_breaks) / 15))
      breaks_to_label <- seq(1, length(hourly_minute_breaks), by = label_density_factor)
      hourly_labels <- rep("", length(hourly_minute_breaks))
      hourly_labels[breaks_to_label] <- sapply(hourly_minute_breaks[breaks_to_label], minutes_to_formatted_string)
    }
  }
  if(length(hourly_minute_breaks) == 0 && nrow(plot_data) > 0) {
    hourly_minute_breaks <- plot_data$TimeValue; hourly_labels <- plot_data$TimeLabelHover
  } else if (length(hourly_minute_breaks) == 0) {
    return(plot_ly() %>% layout(title = paste("无有效数据点用于生成趋势图 - MASKID:", maskid_selected_char)))
  }
  
  # --- Create ggplot object ---
  p <- ggplot(plot_data, aes(x = TimeValue, y = Value)) +
    
    # --- Background Shading ---
    # Make sure rects cover the full range observed or defined
    { if(valid_day_lower && valid_day_upper && d1_day_end_min > d1_day_start_min)
      annotate("rect", xmin = d1_day_start_min, xmax = d1_day_end_min, ymin = day_lower_limit, ymax = day_upper_limit, fill = "#FFF9C4", alpha = 0.4) } + # Day 1 Day
    { if(valid_night_lower && valid_night_upper && d1_night_end_min > d1_night_start_min)
      annotate("rect", xmin = d1_night_start_min, xmax = d1_night_end_min, ymin = night_lower_limit, ymax = night_upper_limit, fill = "#B3E5FC", alpha = 0.4) } + # Day 1 Night
    { if(valid_day_lower && valid_day_upper && d2_day_actual_end_min > d2_day_start_min)
      annotate("rect", xmin = d2_day_start_min, xmax = d2_day_actual_end_min, ymin = day_lower_limit, ymax = day_upper_limit, fill = "#FFF9C4", alpha = 0.4) } + # Day 2 Day (use actual end)
    { if(valid_night_lower && valid_night_upper && d0_night_end_min > d0_night_start_min)
      annotate("rect", xmin = d0_night_start_min, xmax = d0_night_end_min, ymin = night_lower_limit, ymax = night_upper_limit, fill = "#B3E5FC", alpha = 0.4) } + # Day 0 Night
    
    
    # --- Data Line and Points ---
    { if(nrow(plot_data) > 1) geom_line(color = "black", linewidth = 0.8, aes(group = 1)) } +
    geom_point(color = "black", size = 2.5) +
    
    # --- Limit Lines (geom_segment) ---
    # Draw segments covering their respective time periods defined above
    { if(valid_day_upper && d1_day_end_min > d1_day_start_min) annotate("segment", x = d1_day_start_min, xend = d1_day_end_min, y = day_upper_limit, yend = day_upper_limit, color="red", linetype="dashed", linewidth=0.8) } +
    { if(valid_day_lower && d1_day_end_min > d1_day_start_min) annotate("segment", x = d1_day_start_min, xend = d1_day_end_min, y = day_lower_limit, yend = day_lower_limit, color="blue", linetype="dashed", linewidth=0.8) } +
    { if(valid_night_upper && d1_night_end_min > d1_night_start_min) annotate("segment", x = d1_night_start_min, xend = d1_night_end_min, y = night_upper_limit, yend = night_upper_limit, color="red", linetype="dashed", linewidth=0.8) } +
    { if(valid_night_lower && d1_night_end_min > d1_night_start_min) annotate("segment", x = d1_night_start_min, xend = d1_night_end_min, y = night_lower_limit, yend = night_lower_limit, color="blue", linetype="dashed", linewidth=0.8) } +
    { if(valid_day_upper && d2_day_actual_end_min > d2_day_start_min) annotate("segment", x = d2_day_start_min, xend = d2_day_actual_end_min, y = day_upper_limit, yend = day_upper_limit, color="red", linetype="dashed", linewidth=0.8) } +
    { if(valid_day_lower && d2_day_actual_end_min > d2_day_start_min) annotate("segment", x = d2_day_start_min, xend = d2_day_actual_end_min, y = day_lower_limit, yend = day_lower_limit, color="blue", linetype="dashed", linewidth=0.8) } +
    { if(valid_night_upper && d0_night_end_min > d0_night_start_min) annotate("segment", x = d0_night_start_min, xend = d0_night_end_min, y = night_upper_limit, yend = night_upper_limit, color="red", linetype="dashed", linewidth=0.8) } +
    { if(valid_night_lower && d0_night_end_min > d0_night_start_min) annotate("segment", x = d0_night_start_min, xend = d0_night_end_min, y = night_lower_limit, yend = night_lower_limit, color="blue", linetype="dashed", linewidth=0.8) } +
    
    # --- Scales and Theme ---
    scale_y_continuous(limits = y_axis_limits, n.breaks = 6) +
    scale_x_continuous(breaks = hourly_minute_breaks, labels = hourly_labels) +
    labs(title = NULL, x = "时间点", y = paste(metric_name, "值")) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_blank(),
      axis.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size=rel(0.9)),
      legend.position = "none",
      panel.grid.minor = element_blank()
    )
  
  # --- Convert to Plotly ---
  hover_text <- paste("时间:", plot_data$TimeLabelHover, "<br>", metric_name, ":", round(plot_data$Value, 1))
  p_plotly <- ggplotly(p, tooltip = c("x", "y"))
  p_plotly <- apply_point_hover_text(p_plotly, hover_text)
  
  # Title will be set in the server call
  p_plotly <- p_plotly %>% layout(
    margin = list(l = 60, r = 50, t = 50, b = 100)
  )
  
  return(p_plotly)
}

# --- 2.8.3 Donut Chart for Time Distribution --- (Unchanged)
create_time_in_range_donut <- function(results_data, maskid_selected, metric_name) {
  req(results_data)
  if (nrow(results_data) != 1 || !"MASKID" %in% colnames(results_data)) {
    return(plot_ly() %>% layout(title = "输入数据错误 (需要单患者结果)"))
  }
  
  # Construct column names dynamically
  ttr_col <- paste0(metric_name, "_TTR")
  totr_col <- paste0(metric_name, "_TOTR")
  tutr_col <- paste0(metric_name, "_TUTR")
  
  if (!all(c(ttr_col, totr_col, tutr_col) %in% colnames(results_data))) {
    warning(paste("Missing TTR/TOTR/TUTR columns for", metric_name, "in results_data"), call.=FALSE)
    return(plot_ly() %>% layout(title = paste(metric_name, "- TTR/TOTR/TUTR 数据缺失")))
  }
  
  # Extract TTR, TOTR, TUTR values, handle NA -> 0 for plotting
  ttr <- ifelse(is.na(results_data[[ttr_col]][1]) || !is.finite(results_data[[ttr_col]][1]), 0, results_data[[ttr_col]][1])
  totr <- ifelse(is.na(results_data[[totr_col]][1]) || !is.finite(results_data[[totr_col]][1]), 0, results_data[[totr_col]][1])
  tutr <- ifelse(is.na(results_data[[tutr_col]][1]) || !is.finite(results_data[[tutr_col]][1]), 0, results_data[[tutr_col]][1])
  
  total_perc <- ttr + totr + tutr
  if (total_perc > 1e-6 && abs(total_perc - 100) > 1) {
    warning(paste("警告（绘图-时间分布）：TTR/TOTR/TUTR 之和 (", round(total_perc,1), "%) 不等于 100%，MASKID:", maskid_selected, ", 指标:", metric_name))
  }
  
  # Create data frame for plotting
  data <- data.frame(
    category = factor(c("在目标范围", "高于目标范围", "低于目标范围"), levels = c("在目标范围", "高于目标范围", "低于目标范围")),
    value = c(ttr, totr, tutr)
  )
  
  if(sum(data$value) > 1e-6) { data <- data[data$value > 1e-6, ] } # Filter 0s unless all are 0
  
  if(nrow(data) == 0) {
    return(plot_ly() %>% layout(title = paste("患者", maskid_selected, "-", metric_name, "无有效时间分布数据"), xaxis=list(visible=FALSE), yaxis=list(visible=FALSE)) %>%
             add_annotations(x = 0.5, y = 0.5, text = "无数据", showarrow = FALSE, xref = "paper", yref = "paper"))
  }
  
  color_map <- c("在目标范围" = "#4CAF50", "高于目标范围" = "#F44336", "低于目标范围" = "#1565C0")
  my_colors <- color_map[as.character(data$category)]
  
  p <- plot_ly(data, labels = ~category, values = ~value, type = 'pie',
               textposition = 'inside', textinfo = 'percent',
               hoverinfo = 'text', text = ~paste(category, ": ", round(value, 1), "%"),
               marker = list(colors = my_colors, line = list(color = '#FFFFFF', width = 1)),
               sort = FALSE, direction = 'clockwise', hole = 0.6) %>%
    layout(
      # Title added in server call
      showlegend = TRUE,
      legend = list(orientation = "v", traceorder = "normal", font = list(size = 11),x = 1.05, y = 0.5, xanchor = 'left', yanchor = 'middle'),
      margin = list(l = 20, r = 100, t = 40, b = 20),
      paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
      uniformtext = list(minsize=10, mode='hide')
    )
  return(p)
}

# --- 2.8.4 Burden Bar Chart --- (Modified to handle NA burden values)
create_burden_chart <- function(results_data, maskid_selected, metric_name) {
  req(results_data)
  if (nrow(results_data) != 1 || !"MASKID" %in% colnames(results_data)) {
    return(plot_ly() %>% layout(title = "输入数据错误 (需要单患者结果)"))
  }
  
  # Construct column names dynamically
  hyper_col <- paste0(metric_name, "_hyper_Burden")
  hypo_col <- paste0(metric_name, "_hypo_Burden")
  
  if (!all(c(hyper_col, hypo_col) %in% colnames(results_data))) {
    warning(paste("Missing Burden columns for", metric_name, "in results_data"), call.=FALSE)
    return(plot_ly() %>% layout(title = paste(metric_name, "- Burden 数据缺失")))
  }
  
  # Extract hyper and hypo burden values, handle NA/non-finite -> 0 for plotting, but display NA
  hyper_burden_raw <- results_data[[hyper_col]][1]
  hypo_burden_raw <- results_data[[hypo_col]][1]
  
  hyper_burden_plot <- ifelse(is.na(hyper_burden_raw) || !is.finite(hyper_burden_raw), 0, hyper_burden_raw)
  hypo_burden_plot <- ifelse(is.na(hypo_burden_raw) || !is.finite(hypo_burden_raw), 0, hypo_burden_raw)
  
  hyper_burden_display <- if(is.na(hyper_burden_raw) || !is.finite(hyper_burden_raw)) "N/A" else paste0(round(hyper_burden_raw, 1), "%")
  hypo_burden_display <- if(is.na(hypo_burden_raw) || !is.finite(hypo_burden_raw)) "N/A" else paste0(round(hypo_burden_raw, 1), "%")
  
  
  # Create data frame for plotting
  data <- data.frame(
    category = factor(c("升高负担", "偏低负担"), levels = c("升高负担", "偏低负担")),
    value_plot = c(hyper_burden_plot, hypo_burden_plot), # Value for bar height
    value_display = c(hyper_burden_display, hypo_burden_display) # Value for text/hover
  )
  
  bar_colors <- c("升高负担" = "#D32F2F", "偏低负担" = "#1A237E")
  my_colors <- bar_colors[as.character(data$category)]
  
  # Determine y-axis range dynamically based on plot values
  max_val <- max(c(data$value_plot, 0), na.rm = TRUE)
  y_upper_limit <- max(10, max_val * 1.15) # Ensure minimum range of 10%
  if(is.na(y_upper_limit) || !is.finite(y_upper_limit)) y_upper_limit <- 10
  y_range <- c(0, y_upper_limit)
  
  p <- plot_ly(data, x = ~category, y = ~value_plot, type = 'bar',
               marker = list(color = my_colors),
               text = ~value_display, # Use display value for text
               textposition = 'outside', cliponaxis = FALSE,
               hoverinfo = 'text', hovertext = ~paste(category, ": ", value_display)) %>% # Use display value for hover
    layout(
      # Title added in server call
      xaxis = list(title = "", tickfont = list(size = 11)),
      yaxis = list(title = "负担 (%)", titlefont = list(size=12), tickfont = list(size = 11), range = y_range, zeroline = TRUE, zerolinecolor = '#CCCCCC', zerolinewidth = 1, gridcolor = '#EEEEEE'),
      barmode = 'group', bargap = 0.4,
      margin = list(l = 50, r = 20, t = 40, b = 30),
      paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
      uniformtext = list(minsize=10, mode='show')
    )
  return(p)
}


# --- 2.8.5 Variability Bar Chart (Patient vs Reference) --- (Unchanged)
create_variability_chart <- function(results_df, maskid_selected, metric_name, sd_reference, arv_reference) {
  
  # Basic validation
  req(results_df, maskid_selected, metric_name, sd_reference, arv_reference)
  validate(
    need(is.data.frame(results_df) && nrow(results_df) == 1, "变异性图: 需要单行患者结果数据。"),
    need(is.numeric(sd_reference) && is.finite(sd_reference), "变异性图: 参考 SD 必须是有效的数字。"),
    need(is.numeric(arv_reference) && is.finite(arv_reference), "变异性图: 参考 ARV 必须是有效的数字。")
  )
  
  # Construct column names based on metric_name
  sd_col_name <- paste0(metric_name, "_SD")
  arv_col_name <- paste0(metric_name, "_ARV")
  
  validate(
    need(sd_col_name %in% names(results_df), paste("结果数据中缺少列:", sd_col_name)),
    need(arv_col_name %in% names(results_df), paste("结果数据中缺少列:", arv_col_name))
  )
  
  # Extract patient's SD and ARV for the specific period
  patient_sd <- results_df[[sd_col_name]][1]
  patient_arv <- results_df[[arv_col_name]][1]
  
  # Coerce to numeric just in case, handle potential NA/Inf
  patient_sd <- if(is.numeric(patient_sd) && is.finite(patient_sd)) patient_sd else NA_real_
  patient_arv <- if(is.numeric(patient_arv) && is.finite(patient_arv)) patient_arv else NA_real_
  
  # Define colors
  color_below_equal <- "#4CAF50" # Green for below or equal to reference
  color_above <- "#F44336"     # Red for above reference
  color_ref <- "#CCCCCC"       # Gray for reference bars
  color_na <- "#BDBDBD"        # Muted color if patient data is NA
  
  # Determine patient bar colors based on comparison to reference
  sd_color <- if (is.na(patient_sd) || is.na(sd_reference)) {
    color_na
  } else if (patient_sd > sd_reference) {
    color_above
  } else { # Patient SD <= Reference SD
    color_below_equal
  }
  
  arv_color <- if (is.na(patient_arv) || is.na(arv_reference)) {
    color_na
  } else if (patient_arv > arv_reference) {
    color_above
  } else { # Patient ARV <= Reference ARV
    color_below_equal
  }
  
  # Prepare data frames for plotting (one for patient, one for reference)
  patient_data <- data.frame(
    category = c("SD", "ARV"),
    value = c(patient_sd, patient_arv),
    bar_color = c(sd_color, arv_color),
    stringsAsFactors = FALSE
  )
  
  reference_data <- data.frame(
    category = c("SD", "ARV"),
    value = c(sd_reference, arv_reference),
    stringsAsFactors = FALSE
  )
  
  # Determine y-axis range dynamically
  all_values <- c(patient_data$value, reference_data$value)
  all_values <- all_values[!is.na(all_values)] # Remove NA before calculating range
  y_max <- if(length(all_values) > 0 && max(all_values, na.rm = TRUE) > 0) {
    max(all_values, na.rm = TRUE) * 1.20 # Add 20% buffer
  } else {
    # Provide a sensible default if all values are 0, NA, or negative
    max(c(10, sd_reference * 1.2, arv_reference * 1.2), na.rm = TRUE)
  }
  y_range <- c(0, y_max)
  
  # Create the plot using separate traces
  p <- plot_ly() %>%
    add_trace(data = patient_data, x = ~category, y = ~value, type = 'bar',
              name = '患者', # Legend entry for Patient
              marker = list(color = ~bar_color), # Use the pre-calculated bar_color column
              text = ~ifelse(is.na(value), "N/A", sprintf("%.2f", value)), # Display rounded value or N/A
              textposition = 'outside', cliponaxis = FALSE,
              hoverinfo = 'text',
              hovertext = ~paste(category, " (患者): ", ifelse(is.na(value), "N/A", sprintf("%.2f", value)))
    ) %>%
    add_trace(data = reference_data, x = ~category, y = ~value, type = 'bar',
              name = '参考', # Legend entry for Reference
              marker = list(color = color_ref), # Use the fixed reference color
              text = ~ifelse(is.na(value), "N/A", sprintf("%.2f", value)),
              textposition = 'outside', cliponaxis = FALSE,
              hoverinfo = 'text',
              hovertext = ~paste(category, " (参考): ", ifelse(is.na(value), "N/A", sprintf("%.2f", value)))
    ) %>%
    layout(
      # Title added in server call
      xaxis = list(title = "", tickfont = list(size = 11), categoryorder = "array", categoryarray = c("SD", "ARV")), # Ensure order
      yaxis = list(title = "指标值", titlefont = list(size=12), tickfont = list(size = 11), range = y_range, zeroline = TRUE, zerolinecolor = '#CCCCCC', zerolinewidth = 1, gridcolor = '#EEEEEE'),
      barmode = 'group',
      bargap = 0.2,
      # Corrected the duplicate bargap property
      margin = list(l = 50, r = 20, t = 40, b = 30),
      paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
      uniformtext = list(minsize=10, mode='show'),
      legend = list(title=list(text='指标类型'), orientation = 'h', y = -0.2, xanchor = "center", x=0.5) # Updated legend title
    )
  
  return(p)
}


# --- 2.9 Full export and four-dimensional personalized assessment ---
result_scalar <- function(metric_results, period_key, metric, field, patient_id) {
  table <- metric_results[[period_key]][[metric]]
  column <- paste0(metric, "_", field)
  if (is.null(table) || !is.data.frame(table) || !all(c("MASKID", column) %in% names(table))) return(NA_real_)
  value <- table[table$MASKID == patient_id, column, drop = TRUE]
  if (length(value) != 1) return(NA_real_)
  suppressWarnings(as.numeric(value))
}

collect_result_patients <- function(metric_results) {
  ids <- unlist(lapply(metric_results, function(period) {
    unlist(lapply(period, function(table) if (is.data.frame(table) && "MASKID" %in% names(table)) as.character(table$MASKID) else character(0)))
  }))
  sort(unique(ids))
}

build_full_results_wide <- function(metric_results) {
  patient_ids <- collect_result_patients(metric_results)
  result <- data.frame(MASKID = patient_ids, stringsAsFactors = FALSE)
  period_prefix <- c(day = "day", night = "night", `24h` = "24h_unified", `24h_segmented` = "24h_segmented")
  for (period_key in names(period_prefix)) {
    for (metric in names(metric_results[[period_key]])) {
      table <- metric_results[[period_key]][[metric]]
      if (is.null(table) || !is.data.frame(table) || !"MASKID" %in% names(table)) next
      renamed <- table
      metric_columns <- setdiff(names(renamed), "MASKID")
      names(renamed)[match(metric_columns, names(renamed))] <- paste0(period_prefix[[period_key]], "_", metric_columns)
      result <- full_join(result, renamed, by = "MASKID")
    }
  }
  result %>% arrange(MASKID)
}

finite_min <- function(x) if (any(is.finite(x))) min(x[is.finite(x)]) else NA_real_
finite_max <- function(x) if (any(is.finite(x))) max(x[is.finite(x)]) else NA_real_
format_pair <- function(a, b, digits = 1, suffix = "") {
  fmt <- function(x) if (is.finite(x)) paste0(format(round(x, digits), nsmall = digits), suffix) else "N/A"
  paste0("SBP ", fmt(a), " / DBP ", fmt(b))
}

build_personalized_assessment <- function(metric_results, patient_id) {
  periods <- c(`24小时` = "24h_segmented", `白天` = "day", `夜间` = "night")
  period_means <- lapply(periods, function(period_key) c(
    SBP = result_scalar(metric_results, period_key, "SBP", "mean", patient_id),
    DBP = result_scalar(metric_results, period_key, "DBP", "mean", patient_id)
  ))
  guideline_profiles <- list(
    `ESC 2024` = list(`24小时` = c(130, 80), `白天` = c(135, 85), `夜间` = c(120, 70)),
    `AHA/ACC 2025` = list(`24小时` = c(125, 75), `白天` = c(130, 80), `夜间` = c(110, 65)),
    `中国 2024` = list(`24小时` = c(130, 80), `白天` = c(135, 85), `夜间` = c(120, 70))
  )
  guideline_rows <- list()
  for (guideline_name in names(guideline_profiles)) {
    for (period_name in names(periods)) {
      observed <- period_means[[period_name]]
      threshold <- guideline_profiles[[guideline_name]][[period_name]]
      status <- if (!all(is.finite(observed))) {
        "数据不足"
      } else if (observed[["SBP"]] >= threshold[1] || observed[["DBP"]] >= threshold[2]) {
        "达到或超过参考阈值"
      } else {
        "低于参考阈值"
      }
      guideline_rows[[length(guideline_rows) + 1]] <- data.frame(
        指南 = guideline_name,
        时段 = period_name,
        实测均值 = format_pair(observed[["SBP"]], observed[["DBP"]], digits = 1, suffix = " mmHg"),
        参考阈值 = paste0(threshold[1], "/", threshold[2], " mmHg"),
        判断 = status,
        stringsAsFactors = FALSE
      )
    }
  }
  guideline_table <- bind_rows(guideline_rows)

  mean_primary_bad <- any(vapply(names(periods), function(period_name) {
    observed <- period_means[[period_name]]
    threshold <- guideline_profiles[["中国 2024"]][[period_name]]
    all(is.finite(observed)) && (observed[["SBP"]] >= threshold[1] || observed[["DBP"]] >= threshold[2])
  }, logical(1)))

  sbp_sd <- result_scalar(metric_results, "24h_segmented", "SBP", "SD", patient_id)
  dbp_sd <- result_scalar(metric_results, "24h_segmented", "DBP", "SD", patient_id)
  sbp_arv <- result_scalar(metric_results, "24h_segmented", "SBP", "ARV", patient_id)
  dbp_arv <- result_scalar(metric_results, "24h_segmented", "DBP", "ARV", patient_id)
  variability_bad <- finite_max(c(sbp_sd, dbp_sd, sbp_arv, dbp_arv)) >= 10

  sbp_ttr <- result_scalar(metric_results, "24h_segmented", "SBP", "TTR", patient_id)
  dbp_ttr <- result_scalar(metric_results, "24h_segmented", "DBP", "TTR", patient_id)
  ttr_worst <- finite_min(c(sbp_ttr, dbp_ttr))
  ttr_status <- if (!is.finite(ttr_worst)) "数据不足" else if (ttr_worst >= 75) "尚可" else if (ttr_worst >= 50) "欠佳" else "差"

  burden_values <- c(
    result_scalar(metric_results, "24h_segmented", "SBP", "hyper_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "DBP", "hyper_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "SBP", "hypo_Burden", patient_id),
    result_scalar(metric_results, "24h_segmented", "DBP", "hypo_Burden", patient_id)
  )
  burden_worst <- finite_max(burden_values)
  burden_bad <- is.finite(burden_worst) && burden_worst > 5

  mean_24_sbp <- period_means[["24小时"]][["SBP"]]
  mean_24_dbp <- period_means[["24小时"]][["DBP"]]
  max_sbp <- result_scalar(metric_results, "24h_segmented", "SBP", "max_value", patient_id)
  max_dbp <- result_scalar(metric_results, "24h_segmented", "DBP", "max_value", patient_id)
  urgent_flag <- (is.finite(max_sbp) && max_sbp >= 180) || (is.finite(max_dbp) && max_dbp >= 120) ||
    (is.finite(mean_24_sbp) && mean_24_sbp >= 145) || (is.finite(mean_24_dbp) && mean_24_dbp >= 90)

  followup <- if (urgent_flag) {
    "请尽快就医"
  } else if (mean_primary_bad || isTRUE(variability_bad) || (!is.na(ttr_status) && ttr_status %in% c("欠佳", "差")) || burden_bad) {
    "可择期就医"
  } else {
    "定期随访"
  }

  suggestions <- character(0)
  if (mean_primary_bad) suggestions <- c(suggestions, "平均血压至少一个时段达到中国/ESC动态血压参考阈值：建议结合用药依从性、家庭血压和心血管危险因素，由医生复核治疗方案；不要自行加减药。")
  if (isTRUE(variability_bad)) suggestions <- c(suggestions, "SD或ARV达到10 mmHg：先核查测量有效性、睡眠/活动、情绪及服药时间；可与医生讨论复测ABPM及长效平稳控压策略。")
  if (is.finite(ttr_worst) && ttr_worst < 75) suggestions <- c(suggestions, if (ttr_worst < 50) "TTR低于50%，全天稳定达标较差，建议近期复诊并重点查看超标/偏低发生时段。" else "TTR为50%–<75%，控制稳定性欠佳，建议分析日夜分布并择期复诊。")
  if (burden_bad) suggestions <- c(suggestions, "高值或低值Burden超过5%：建议定位发生时段；低值负担伴头晕、乏力或跌倒风险时应更早就医。")
  if (length(suggestions) == 0) suggestions <- c(suggestions, "四维度当前未见明显失控信号；继续规范用药、限盐、规律活动、体重与睡眠管理，并按既定计划随访。")
  suggestions <- c(suggestions, "如复测血压仍≥180/120 mmHg，或伴胸痛、呼吸困难、神经功能缺损、意识改变等症状，请立即急诊。")

  dimension_table <- data.frame(
    维度 = c("平均血压 Mean", "波动 SD/ARV", "达标时间 TTR", "血压负荷 Burden"),
    当前结果 = c(
      format_pair(mean_24_sbp, mean_24_dbp, 1, " mmHg (24h)"),
      paste0("SD: ", format_pair(sbp_sd, dbp_sd), "；ARV: ", format_pair(sbp_arv, dbp_arv)),
      format_pair(sbp_ttr, dbp_ttr, 1, "%"),
      if (is.finite(burden_worst)) paste0("最不利值 ", round(burden_worst, 1), "%") else "N/A"
    ),
    判定标准 = c("并列参考ESC 2024、AHA/ACC 2025、中国2024", "SD和ARV均<10 mmHg为佳", "≥75%尚可；50%–<75%欠佳；<50%差", "高值/低值Burden均≤5%为佳"),
    判断 = c(if (mean_primary_bad) "需关注" else "中国/ESC阈值内",
             if (isTRUE(variability_bad)) "不佳" else "尚可",
             ttr_status,
             if (burden_bad) "不佳" else if (is.finite(burden_worst)) "尚可" else "数据不足"),
    stringsAsFactors = FALSE
  )

  list(
    MASKID = patient_id,
    followup = followup,
    dimensions = dimension_table,
    guidelines = guideline_table,
    suggestions = suggestions,
    export_row = data.frame(
      MASKID = patient_id,
      随诊建议 = followup,
      Mean判断 = dimension_table$判断[1],
      SD_ARV判断 = dimension_table$判断[2],
      TTR判断 = dimension_table$判断[3],
      Burden判断 = dimension_table$判断[4],
      个性化建议 = paste(suggestions, collapse = "；"),
      stringsAsFactors = FALSE
    )
  )
}

build_all_personalized_assessments <- function(metric_results) {
  ids <- collect_result_patients(metric_results)
  if (length(ids) == 0) return(data.frame())
  bind_rows(lapply(ids, function(id) build_personalized_assessment(metric_results, id)$export_row))
}


# --- 3. UI Definition (MODIFIED FOR 24H SEGMENTED) ---
ui <- fluidPage(
  theme = shinytheme("flatly"),
  shinyjs::useShinyjs(),
  
  tags$head( # Add custom CSS for better panel headers/borders
    tags$style(HTML("
      .well h5 { margin-top: 0; margin-bottom: 10px; font-weight: bold; }
      .summary-well { background-color: #f0f9ff; border: 1px solid #b3e0ff; border-radius: 5px; padding: 10px 15px; min-height: 130px; }
      .stats-well { background-color: #f8f9fa; border-radius: 5px; padding: 10px 15px; min-height: 130px; }
      .plot-well { background-color: #ffffff; border: 1px solid #ddd; border-radius: 5px; padding: 5px; margin-bottom: 15px; }
      .plot-well-header { padding: 8px 15px; background-color: #f5f5f5; border-bottom: 1px solid #ddd; border-radius: 5px 5px 0 0; font-weight: bold; color: #337ab7;}
      .plot-well-body { padding: 15px; }
    "))
  ),
  
  titlePanel(
    windowTitle = "ABPM 新型指标分析系统 Ver1.0.0", # Updated Version
    title = div(
      icon("heart-pulse"),
      "ABPM 新型指标分析系统",
      span("（中文版, Version 1.0.0）", style = "font-size: 0.7em; color: #555;") # Updated Version
    )
  ),
  
  sidebarLayout(
    # --- Sidebar Panel (Unchanged) ---
    sidebarPanel(
      width = 3,
      h4(icon("database"), "数据来源"),
      fileInput("file1", "选择 ABPM CSV 文件",
                multiple = FALSE,
                accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
      checkboxInput("use_builtin_data", "使用内置示例数据 (P001-P002)", value = TRUE),
      wellPanel(
        style = "padding: 10px; background-color: #f8f9fa;",
        p(icon("info-circle"), tags$strong("数据格式要求：")),
        tags$ul(style="font-size: 0.85em; padding-left: 20px; color: #333;",
                tags$li("文件必须是 CSV 格式 (UTF-8 编码优先)。"),
                tags$li("首列: MASKID (患者ID)。"),
                tags$li("第二列: Time (时间, 格式为 HHMM+DD 或 HHMM)。"),
                tags$li(tags$strong("必需列:"), " SBP, DBP, HR (数值)。"),
                tags$li(tags$strong("可选列:"), " PP, MAP (将尝试计算)。"),
                tags$li("列名区分大小写。")
        )
      ),
      hr(), # Separator
      
      h4(icon("clock"), "日间/夜间时间定义 (精确到分钟)"),
      tags$label("第一天白天开始时间 (HH:MM):"),
      fluidRow(
        column(5, style="padding-right:1px;", numericInput("day1_start_h", NULL, value = 7, min = 0, max = 23, step = 1)),
        column(2, style="padding-left:1px; padding-right:1px; text-align: center; line-height: 34px;", tags$strong(":")),
        column(5, style="padding-left:1px;", numericInput("day1_start_m", NULL, value = 0, min = 0, max = 59, step = 1))
      ),
      tags$label("第一天夜晚开始时间 (HH:MM):"),
      fluidRow(
        column(5, style="padding-right:1px;", numericInput("day1_night_start_h", NULL, value = 22, min = 0, max = 23, step = 1)),
        column(2, style="padding-left:1px; padding-right:1px; text-align: center; line-height: 34px;", tags$strong(":")),
        column(5, style="padding-left:1px;", numericInput("day1_night_start_m", NULL, value = 0, min = 0, max = 59, step = 1))
      ),
      tags$label("第二天白天开始时间 (HH:MM):"),
      fluidRow(
        column(5, style="padding-right:1px;", numericInput("day2_start_h", NULL, value = 7, min = 0, max = 23, step = 1)),
        column(2, style="padding-left:1px; padding-right:1px; text-align: center; line-height: 34px;", tags$strong(":")),
        column(5, style="padding-left:1px;",numericInput("day2_start_m", NULL, value = 0, min = 0, max = 59, step = 1))
      ),
      tags$label("第二天夜晚开始时间 (HH:MM):"),
      fluidRow(
        column(5, style="padding-right:1px;", numericInput("day2_night_start_h", NULL, value = 22, min = 0, max = 23, step = 1)),
        column(2, style="padding-left:1px; padding-right:1px; text-align: center; line-height: 34px;", tags$strong(":")),
        column(5, style="padding-left:1px;", numericInput("day2_night_start_m", NULL, value = 0, min = 0, max = 59, step = 1))
      ),
      h5("时间定义快速预设:", style="margin-top: 15px; margin-bottom: 5px;"),
      fluidRow(
        column(6, actionButton("preset_east_asia", "东亚 (05-20)", class = "btn-sm btn-block btn-info")),
        column(6, actionButton("preset_western", "欧美 (07-22)", class = "btn-sm btn-block btn-primary"))
      ),
      hr(), # Separator
      
      # --- Data Processing Button ---
      div(style = "margin-bottom: 10px;",
          actionButton("process_data_btn", "1. 处理数据", icon=icon("cogs"), class = "btn-primary btn-lg btn-block")
      ),
      hr(), # Separator
      
      # --- Target Range Settings ---
      h4(icon("bullseye"), "指标目标范围设置"),
      div(
        class = "alert alert-info",
        style = "padding:8px 10px; margin-bottom:10px; font-size:0.9em;",
        tags$strong("三套阈值输入，生成四套结果："),
        "日间结果使用日间阈值；夜间结果使用夜间阈值；24h日夜统一结果使用24h统一阈值；",
        "24h日夜分段结果自动复用日间/夜间阈值。PP、MAP可留空，也可由SBP/DBP自动推导。"
      ),
      tabsetPanel(
        id = "target_tabs",
        tabPanel("日间阈值",
                 fluidRow(column(6, numericInput("sbp_day_lower", "SBP 下限", 90)), column(6, numericInput("sbp_day_upper", "SBP 上限", 120))),
                 fluidRow(column(6, numericInput("dbp_day_lower", "DBP 下限", 55)), column(6, numericInput("dbp_day_upper", "DBP 上限", 70))),
                 fluidRow(column(6, numericInput("hr_day_lower", "HR 下限", 60)), column(6, numericInput("hr_day_upper", "HR 上限", 100))),
                 fluidRow(column(6, numericInput("pp_day_lower", "PP 下限", NA)), column(6, numericInput("pp_day_upper", "PP 上限", NA))),
                 fluidRow(column(6, numericInput("map_day_lower", "MAP 下限", NA)), column(6, numericInput("map_day_upper", "MAP 上限", NA)))
        ),
        tabPanel("夜间阈值",
                 fluidRow(column(6, numericInput("sbp_night_lower", "SBP 下限", 90)), column(6, numericInput("sbp_night_upper", "SBP 上限", 110))),
                 fluidRow(column(6, numericInput("dbp_night_lower", "DBP 下限", 55)), column(6, numericInput("dbp_night_upper", "DBP 上限", 60))),
                 fluidRow(column(6, numericInput("hr_night_lower", "HR 下限", 50)), column(6, numericInput("hr_night_upper", "HR 上限", 90))),
                 fluidRow(column(6, numericInput("pp_night_lower", "PP 下限", NA)), column(6, numericInput("pp_night_upper", "PP 上限", NA))),
                 fluidRow(column(6, numericInput("map_night_lower", "MAP 下限", NA)), column(6, numericInput("map_night_upper", "MAP 上限", NA)))
        ),
        tabPanel("24h日夜统一阈值",
                 fluidRow(column(6, numericInput("sbp_24h_lower", "SBP 下限", 90)), column(6, numericInput("sbp_24h_upper", "SBP 上限", 115))),
                 fluidRow(column(6, numericInput("dbp_24h_lower", "DBP 下限", 55)), column(6, numericInput("dbp_24h_upper", "DBP 上限", 65))),
                 fluidRow(column(6, numericInput("hr_24h_lower", "HR 下限", 55)), column(6, numericInput("hr_24h_upper", "HR 上限", 95))),
                 fluidRow(column(6, numericInput("pp_24h_lower", "PP 下限", NA)), column(6, numericInput("pp_24h_upper", "PP 上限", NA))),
                 fluidRow(column(6, numericInput("map_24h_lower", "MAP 下限", NA)), column(6, numericInput("map_24h_upper", "MAP 上限", NA)))
        )
      ),
      actionButton("apply_targets_btn", "自动计算 PP/MAP 范围", icon=icon("magic"), class = "btn-sm btn-info btn-block", style="margin-top: 10px;"),
      actionButton("preset_targets", "应用默认目标范围", icon=icon("bullseye"), class = "btn-sm btn-warning btn-block", style="margin-top: 5px;"),
      shinyjs::disabled( # Initially disable save button
        actionButton("save_custom_targets_btn", "保存并锁定自定义范围", icon=icon("lock"), class = "btn-sm btn-success btn-block", style="margin-top: 5px; margin-bottom: 10px;")
      ),
      
      hr(), # Separator
      
      # --- Calculation Button ---
      div(style = "margin-bottom: 10px;",
          shinyjs::disabled( # Initially disable calculation button
            actionButton("calculate_metrics_btn", "2. 计算指标", icon=icon("calculator"), class = "btn-success btn-lg btn-block")
          )
      )
    ), # End sidebarPanel
    
    # --- Main Panel (MODIFIED FOR 24H SEGMENTED) ---
    mainPanel(
      width = 9,
      tabsetPanel(id="main_tabset", type = "tabs",
                  tabPanel(title = span(icon("file-alt"), " 查看输入数据"), value="raw_data_tab",
                           br(), h4(textOutput("data_source_title")), DTOutput("raw_data_table")),
                  tabPanel(title = span(icon("wrench"), " 处理过程数据"), value="processed_data_tab",
                           br(),
                           tabsetPanel(id="processing_subtabs",
                                       tabPanel(title = "准备后长格式 & 宽格式(插补前)", value="prepared_long",
                                                br(), h5("准备后的长格式数据"), DTOutput("prepared_long_table"),
                                                hr(), h5("宽格式数据 (插补前)"), uiOutput("wide_data_tabs")
                                       ),
                                       tabPanel(title = "宽格式 (插补后, 原始时间)", value="wide_interpolated",
                                                br(), h5("使用线性插补填充内部缺失值"), uiOutput("interpolated_data_tabs")
                                       )
                           )
                  ),
                  tabPanel(title = span(icon("columns"), " 分段数据"), value="split_data_tab",
                           br(), h5("基于【插补后宽格式】数据按设定时间段分割"),
                           tabsetPanel(id="split_period_tabs",
                                       tabPanel(title = span(icon("cloud-moon"),"Day 0 夜"), value="day0_night",
                                                br(), uiOutput("split_day0_night_metric_tabs")
                                       ),
                                       tabPanel(title = span(icon("sun"),"Day 1 白天"), value="day1_day",
                                                br(), uiOutput("split_day1_day_metric_tabs")
                                       ),
                                       tabPanel(title = span(icon("moon"),"Day 1 夜晚"), value="day1_night",
                                                br(), uiOutput("split_day1_night_metric_tabs")
                                       ),
                                       tabPanel(title = span(icon("cloud-sun"), "Day 2 白天"), value="day2_day",
                                                br(), uiOutput("split_day2_day_metric_tabs")
                                       ),
                                       tabPanel(title = span(icon("hourglass-half"), "24h 整体 (插补后)"), value="full_24h_interp",
                                                br(), h5("完整的插补后宽格式数据 (用于24小时指标计算)"),
                                                uiOutput("full_24h_interpolated_data_tabs")
                                       )
                           )
                  ),
                  # --- MODIFIED Results Tab Panel ---
                  tabPanel(title = span(icon("table"), " 指标计算结果"), value="results_tab",
                           br(),
                           fluidRow(
                             column(12,
                                    div(style = "text-align:right; margin-bottom:10px;",
                                        downloadButton("download_all_csv", "导出四套结果·全部患者 CSV", class = "btn-info"),
                                        downloadButton("download_all_xlsx", "导出四套结果·全部患者 Excel", class = "btn-success")
                                    ),
                                    tags$p(
                                      "包含日间、夜间、24h日夜统一阈值、24h日夜分段阈值四套结果；不受表格分页、筛选或当前页面影响。",
                                      style = "text-align:right; color:#666; margin-top:4px; margin-bottom:8px; font-size:0.9em;"
                                    )
                             )
                           ),
                           tabsetPanel(id="results_period_tabs",
                                       tabPanel(title = "日间（使用日间阈值）", value="day_results",
                                                br(),
                                                uiOutput("target_ranges_day_display"),
                                                hr(style="border-top: 1px solid #ccc;"),
                                                uiOutput("day_metric_tabs")
                                       ),
                                       tabPanel(title = "夜间（使用夜间阈值）", value="night_results",
                                                br(),
                                                uiOutput("target_ranges_night_display"),
                                                hr(style="border-top: 1px solid #ccc;"),
                                                uiOutput("night_metric_tabs")
                                       ),
                                       # --- Existing: 24h Unified Results Tab ---
                                       tabPanel(title = "24h（日夜统一阈值）", value="results_24h_unified",
                                                br(),
                                                uiOutput("target_ranges_24h_unified_display"),
                                                hr(style="border-top: 1px solid #ccc;"),
                                                uiOutput("24h_unified_metric_tabs")
                                       ),
                                       # --- NEW: 24h Segmented (Day/Night) Results Tab ---
                                       tabPanel(title = "24h（日夜分段阈值）", value="results_24h_segmented",
                                                br(),
                                                uiOutput("target_ranges_daynight_display_combined"), # Display combined day/night limits used
                                                hr(style="border-top: 1px solid #ccc;"),
                                                # Display tables for the segmented calculation results
                                                uiOutput("segmented_24h_metric_tabs") # New UI output for segmented tables
                                       )
                           )
                  ),
                  # --- MODIFIED Visualization Tab Panel ---
                  tabPanel(title = span(icon("chart-area"), " 可视化分析"), value="viz_tab",
                           br(),
                           # --- Top Row: Selection (Unchanged) ---
                           fluidRow(
                             column(4,
                                    wellPanel(
                                      style = "background-color: #f8f9fa; border-radius: 5px; padding: 15px; border: 1px solid #ddd;",
                                      selectInput("viz_maskid", label=tagList(icon("user"), "选择患者 (MASKID):"), choices = NULL, width = "100%"),
                                      selectInput("viz_metric_select", label=tagList(icon("stethoscope"), "选择显示指标:"), choices=c("SBP", "DBP", "HR", "PP", "MAP"), selected="SBP", width="100%")
                                    )
                             ),
                             column(8,
                                    wellPanel(
                                      class = "summary-well",
                                      h5(icon("binoculars"), "患者指标概览（基于24h日夜统一阈值结果）", style="color: #0056b3;"), # Clarified source
                                      uiOutput("viz_summary_header") # Display key info here
                                    )
                             )
                           ),
                           hr(),
                           
                           # --- Sub-tabs for Unified 24h, Segmented 24h, Day, Night ---
                           tabsetPanel(id = "viz_sub_tabset", type = "pills",
                                       
                                       # --- Existing: 24小时 (统一限值) Sub-tab ---
                                       tabPanel(title = span(icon("hourglass-half"), " 24h（日夜统一阈值）"), value = "viz_24h_unified",
                                                br(),
                                                fluidRow(
                                                  column(6,
                                                         wellPanel(class = "summary-well",
                                                                   h5(icon("clipboard-check"), "关键指标概览（24h日夜统一阈值）"),
                                                                   uiOutput("viz_info_24h_unified") # Uses unified 24h results
                                                         )
                                                  ),
                                                  column(6,
                                                         wellPanel(class = "stats-well",
                                                                   h5(icon("clipboard-list"), "统计摘要（24h日夜统一阈值）"),
                                                                   verbatimTextOutput("patient_summary_24h_unified") # Uses unified 24h results
                                                         )
                                                  )
                                                ),
                                                fluidRow(
                                                  column(12,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("chart-line"), "指标趋势图 (采用统一24小时限值 & 背景)"),
                                                             div(class = "plot-well-body", plotlyOutput("bp_trend_chart_24h_unified_limit", height = "450px")) # Uses generic trend chart
                                                         )
                                                  )
                                                ),
                                                br(),
                                                fluidRow(
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("chart-pie"), "时间分布（24h日夜统一阈值）"),
                                                             div(class = "plot-well-body", plotlyOutput("time_in_range_donut_24h_unified", height = "350px")) # Uses unified 24h results
                                                         )
                                                  ),
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("tachometer-alt"), "负担指标（24h日夜统一阈值）"),
                                                             div(class = "plot-well-body", plotlyOutput("burden_chart_24h_unified", height = "350px")) # Uses unified 24h results
                                                         )
                                                  ),
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("wave-square"), "变异性指标（24h日夜统一阈值，对照参考值）"),
                                                             div(class = "plot-well-body", plotlyOutput("variability_chart_24h_unified", height = "350px")) # Uses unified 24h results
                                                         )
                                                  )
                                                )
                                       ), # End 24h (unified) tabPanel
                                       
                                       # --- NEW: 24小时 (日夜分段限值) Sub-tab ---
                                       tabPanel(title = span(icon("adjust"), " 24h（日夜分段阈值）"), value = "viz_24h_segmented",
                                                br(),
                                                fluidRow(
                                                  column(12,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("chart-line"), "指标趋势图 (区分日夜限值 & 背景)"),
                                                             div(class = "plot-well-body", plotlyOutput("bp_trend_chart_24h_segmented_limits", height = "450px")) # New ID, uses create_metric_trend_chart_24h
                                                         )
                                                  )
                                                ),
                                                br(),
                                                # Display calculated segmented results below the trend chart
                                                p(tags$strong("24h（日夜分段阈值）计算结果："), style="font-size: 1.1em; color: #286090;"),
                                                p("注意：以下图表基于日间和夜间数据结合计算，使用各自时段的目标限值。", style="font-style: italic;"),
                                                fluidRow(
                                                  column(6,
                                                         wellPanel(class = "summary-well", style="background-color: #e8f5e9; border-color: #c8e6c9;", # Light green background
                                                                   h5(icon("clipboard-check"), "关键指标概览（24h日夜分段阈值）"),
                                                                   uiOutput("viz_info_24h_segmented") # New ID - Uses segmented 24h results
                                                         )
                                                  ),
                                                  column(6,
                                                         wellPanel(class = "stats-well",
                                                                   h5(icon("clipboard-list"), "统计摘要（24h日夜分段阈值）"),
                                                                   verbatimTextOutput("patient_summary_24h_segmented") # New ID - Uses segmented 24h results
                                                         )
                                                  )
                                                ),
                                                fluidRow(
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("chart-pie"), "时间分布（24h日夜分段阈值）"),
                                                             div(class = "plot-well-body", plotlyOutput("time_in_range_donut_24h_segmented", height = "350px")) # New ID - Uses segmented 24h results
                                                         )
                                                  ),
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("tachometer-alt"), "负担指标（24h日夜分段阈值）"),
                                                             div(class = "plot-well-body", plotlyOutput("burden_chart_24h_segmented", height = "350px")) # New ID - Uses segmented 24h results
                                                         )
                                                  ),
                                                  column(4,
                                                         div(class = "plot-well",
                                                             div(class = "plot-well-header", icon("wave-square"), "变异性指标 (24h整体, vs 参考值)"),
                                                             div(class = "plot-well-body", plotlyOutput("variability_chart_24h_segmented", height = "350px")) # New ID - Uses segmented 24h results (SD/ARV based on whole 24h data)
                                                         )
                                                  )
                                                )
                                       ), # End 24h (segmented) tabPanel
                                       
                                       
                                       # --- 白天 Sub-tab (Shows Day results and segmented trend plot) ---
                                       tabPanel(title = span(icon("sun"), " 白天"), value = "viz_day",
                                                br(),
                                                fluidRow(
                                                  column(6, wellPanel(class = "summary-well", h5(icon("clipboard-check"), "关键指标概览 (白天)"), uiOutput("viz_info_day"))),
                                                  column(6, wellPanel(class = "stats-well", h5(icon("clipboard-list"), "统计摘要 (白天)"), verbatimTextOutput("patient_summary_day")))
                                                ),
                                                fluidRow(
                                                  column(12, div(class = "plot-well", div(class = "plot-well-header", icon("chart-line"), "指标趋势图（同24h日夜分段阈值视图）"), div(class = "plot-well-body", plotlyOutput("bp_trend_chart_day", height = "450px")))) # Clarified it shows the same as segmented 24h plot
                                                ),
                                                br(),
                                                fluidRow(
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("chart-pie"), "时间分布 (白天)"), div(class = "plot-well-body", plotlyOutput("time_in_range_donut_day", height = "350px")))),
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("tachometer-alt"), "负担指标 (白天)"), div(class = "plot-well-body", plotlyOutput("burden_chart_day", height = "350px")))),
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("wave-square"), "变异性指标 (白天, vs 参考值)"), div(class = "plot-well-body", plotlyOutput("variability_chart_day", height = "350px"))))
                                                )
                                       ), # End day tabPanel
                                       
                                       # --- 夜晚 Sub-tab (Shows Night results and segmented trend plot) ---
                                       tabPanel(title = span(icon("moon"), " 夜晚"), value = "viz_night",
                                                br(),
                                                fluidRow(
                                                  column(6, wellPanel(class = "summary-well", h5(icon("clipboard-check"), "关键指标概览 (夜晚)"), uiOutput("viz_info_night"))),
                                                  column(6, wellPanel(class = "stats-well", h5(icon("clipboard-list"), "统计摘要 (夜晚)"), verbatimTextOutput("patient_summary_night")))
                                                ),
                                                fluidRow(
                                                  column(12, div(class = "plot-well", div(class = "plot-well-header", icon("chart-line"), "指标趋势图（同24h日夜分段阈值视图）"), div(class = "plot-well-body", plotlyOutput("bp_trend_chart_night", height = "450px")))) # Clarified it shows the same as segmented 24h plot
                                                ),
                                                br(),
                                                fluidRow(
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("chart-pie"), "时间分布 (夜晚)"), div(class = "plot-well-body", plotlyOutput("time_in_range_donut_night", height = "350px")))),
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("tachometer-alt"), "负担指标 (夜晚)"), div(class = "plot-well-body", plotlyOutput("burden_chart_night", height = "350px")))),
                                                  column(4, div(class = "plot-well", div(class = "plot-well-header", icon("wave-square"), "变异性指标 (夜晚, vs 参考值)"), div(class = "plot-well-body", plotlyOutput("variability_chart_night", height = "350px"))))
                                                )
                                       ) # End night tabPanel
                           ) # End viz_sub_tabset
                  ), # End tabPanel "可视化分析"

                  # --- New Personalized Analysis Tab (only new analysis page) ---
                  tabPanel(title = span(icon("user-check"), " 个性化分析"), value = "personal_analysis_tab",
                           br(),
                           fluidRow(
                             column(4,
                                    wellPanel(
                                      selectInput("analysis_maskid", "选择患者 (MASKID):", choices = NULL, width = "100%"),
                                      p(style = "font-size:0.85em;color:#666;",
                                        "四维度判定使用24h（日夜分段阈值）结果；Mean同时展示三套指南解释。")
                                    )
                             ),
                             column(8,
                                    wellPanel(class = "summary-well",
                                              h5(icon("notes-medical"), "随诊分级"),
                                              uiOutput("personal_followup_level"))
                             )
                           ),
                           h4(icon("project-diagram"), "血压控制四维度"),
                           DTOutput("personal_dimension_table"),
                           br(),
                           h4(icon("book-medical"), "Mean：指南并列参考"),
                           DTOutput("personal_guideline_table"),
                           br(),
                           h4(icon("comment-medical"), "个性化建议"),
                           uiOutput("personal_advice"),
                           wellPanel(
                             style = "font-size:0.85em;color:#555;",
                             tags$strong("说明："),
                             "本页为基于ABPM数据的辅助分层，不能替代诊断、症状评估、既往病史和医生面诊。",
                             tags$br(),
                             a("ESC 2024 指南", href = "https://www.escardio.org/guidelines/clinical-practice-guidelines/all-esc-practice-guidelines/elevated-blood-pressure-and-hypertension/", target = "_blank"),
                             "；",
                             a("AHA/ACC 2025 指南", href = "https://professional.heart.org/en/science-news/2025-high-blood-pressure-guideline", target = "_blank"),
                             "；",
                             a("中国高血压防治指南（2024年修订版）", href = "https://pmc.ncbi.nlm.nih.gov/articles/PMC11937835/", target = "_blank")
                           )
                  ),
                  
                  # --- Help Tab (Updated for new features) ---
                  tabPanel(title = span(icon("question-circle"), " 使用说明"), value="help_tab",
                           br(),
                           fluidRow(
                             column(12,
                                    div(class = "panel panel-default",
                                        div(class = "panel-heading", style = "background-color: #f5f5f5;",
                                            h4(icon("book-reader"), "ABPM 新型指标分析系统使用指南", style = "text-align: center; margin: 5px 0;")
                                        ),
                                        div(class = "panel-body", style="font-size: 0.95em;",
                                            h5(tags$strong("1. ", icon("upload"), " 数据加载")),
                                            tags$ul(
                                              tags$li("使用【内置示例数据】或【选择 ABPM CSV 文件】加载数据。"),
                                              tags$li("检查侧边栏【数据格式要求】。"),
                                              tags$li("在【查看输入数据】选项卡预览。"), br()
                                            ),
                                            
                                            h5(tags$strong("2. ", icon("clock"), " 定义日夜时间")),
                                            tags$ul(
                                              tags$li("输入Day1/Day2的【白天开始时间】和【夜晚开始时间】。"),
                                              tags$li("可使用【东亚】或【欧美】快速预设按钮。"), br()
                                            ),
                                            
                                            h5(tags$strong("3. ", icon("cogs"), " 数据处理")),
                                            tags$ul(
                                              tags$li("点击【1. 处理数据】按钮。"),
                                              tags$li("系统执行：清洗校验 ", icon("check-double"), " -> 时间标准化 ", icon("sort-numeric-down"), " -> 宽数据转换 ", icon("table"), " -> 逐患者独立时间轴与必要边界插补 ", icon("chart-line"), " -> 时段分割 ", icon("cut"), "。"),
                                              tags$li("处理中间数据可在【处理过程数据】和【分段数据】查看。"),
                                              tags$li("成功后，下方按钮启用。"), br()
                                            ),
                                            
                                            h5(tags$strong("4. ", icon("bullseye"), " 设置目标范围")),
                                            tags$ul(
                                              tags$li("为【白天】/【夜晚】/【24小时 (统一)】分别设置SBP/DBP/HR上下限。"),
                                              tags$li("PP/MAP范围可选：上下限必须成对填写，或同时留空；留空时不计算其阈值相关指标。"),
                                              tags$li("【自动计算 PP/MAP 范围】分别读取日间、夜间、24h日夜统一三组SBP/DBP；HR不参与PP/MAP公式。"),
                                              tags$li("【应用默认目标范围】恢复三组SBP/DBP/HR预设值，并同步推导三组PP/MAP。"),
                                              tags$li("【保存并锁定自定义范围】固定本次计算快照；锁定后同一按钮变为【解除目标范围锁定】，解锁时保留当前值。"), br()
                                            ),
                                            
                                            h5(tags$strong("5. ", icon("calculator"), " 计算指标")),
                                            tags$ul(
                                              tags$li("点击【2. 计算指标】按钮。"),
                                              tags$li("系统使用【当前目标范围】计算以下指标:"),
                                              tags$ul(
                                                tags$li("日间（使用日间阈值）"),
                                                tags$li("夜间（使用夜间阈值）"),
                                                tags$li("24h（日夜统一阈值）：使用24h统一目标范围计算完整时段。"),
                                                tags$li("24h（日夜分段阈值）：同一患者内，日间使用日间阈值、夜间使用夜间阈值，再合并时间与面积结果。")
                                              ),
                                              tags$li("结果显示在【指标计算结果】选项卡相应子页签，可导出。"), br()
                                            ),
                                            
                                            h5(tags$strong("6. ", icon("chart-area"), " 可视化分析")),
                                            tags$ul(
                                              tags$li("选择【患者】和【指标】。"),
                                              tags$li("在【24h（日夜统一阈值）】/【24h（日夜分段阈值）】/【日间】/【夜间】页签查看："), # Updated help text
                                              tags$ul(
                                                tags$li(icon("info-circle"), " 概览与摘要 (基于对应计算结果)。"),
                                                tags$li(icon("chart-line"), " 趋势图：【24h（日夜统一阈值）】页显示统一阈值背景；【24h（日夜分段阈值）】/【日间】/【夜间】页显示区分日夜阈值背景。"),
                                                tags$li(icon("chart-pie"), " 时间分布图 (基于对应计算结果)。"),
                                                tags$li(icon("tachometer-alt"), " 负担图 (基于对应计算结果)。"),
                                                tags$li(icon("wave-square"), " 变异性图 (SD/ARV基于对应时段数据, vs 参考值)。")
                                              )
                                            ),
                                            
                                            # --- Metrics Table (Unchanged) ---
                                            h5(tags$strong("7. ", icon("tag"), " 指标解释"), style = "margin-top: 15px;"),
                                            div(style="max-height: 400px; overflow-y: auto;", # Scrollable div
                                                tags$table(class = "table table-striped table-bordered table-condensed", style = "font-size: 0.9em;",
                                                           tags$thead(
                                                             tags$tr(
                                                               tags$th("指标 (Metric)"), tags$th("时段 (Period Result Tab)"), tags$th("含义"), tags$th("注释/意义")
                                                             )
                                                           ),
                                                           tags$tbody(
                                                             tags$tr(tags$td("TTR"), tags$td("各时段"), tags$td("Time in Target Range (%)"), tags$td("目标范围内时间比例, 越高越好")),
                                                             tags$tr(tags$td("TOTR"), tags$td("各时段"), tags$td("Time Over Target Range (%)"), tags$td("高于目标范围时间比例, 越低越好")),
                                                             tags$tr(tags$td("TUTR"), tags$td("各时段"), tags$td("Time Under Target Range (%)"), tags$td("低于目标范围时间比例, 越低越好")),
                                                             tags$tr(tags$td("hyper_Burden"), tags$td("各时段"), tags$td("Hypertension/Hyper Burden (%)"), tags$td("高值负担(综合时间和幅度), 越低越好")),
                                                             tags$tr(tags$td("hypo_Burden"), tags$td("各时段"), tags$td("Hypotension/Hypo Burden (%)"), tags$td("低值负担(综合时间和幅度), 越低越好")),
                                                             tags$tr(tags$td("cumulative_Load"), tags$td("各时段"), tags$td("Cumulative Load (%)"), tags$td("累积负荷 (Sa / Sd * 100)")),
                                                             tags$tr(tags$td("Load"), tags$td("各时段"), tags$td("Load (%)"), tags$td("超出上限的真实测量次数百分比 (不使用插补值)")),
                                                             tags$tr(tags$td("mean"), tags$td("各时段"), tags$td("Mean Value"), tags$td("平均值 (仅基于真实测量值)")),
                                                             tags$tr(tags$td("SD"), tags$td("各时段"), tags$td("Standard Deviation"), tags$td("标准差 (样本)，评估波动性")),
                                                             tags$tr(tags$td("CV"), tags$td("各时段"), tags$td("Coefficient of Variation (%)"), tags$td("变异系数 (SD / |Mean| * 100)")),
                                                             tags$tr(tags$td("ARV"), tags$td("各时段"), tags$td("Average Real Variability"), tags$td("按时间排序的相邻真实测量值差值绝对均值")),
                                                             tags$tr(tags$td("VIM"), tags$td("各时段"), tags$td("Variability Independent of the Mean"), tags$td("基于真实值Mean/SD及同批次标准β；样本不足时为NA")),
                                                             tags$tr(tags$td("max_value"), tags$td("各时段"), tags$td("Maximum Value"), tags$td("最大值 (仅基于真实测量值)")),
                                                             tags$tr(tags$td("min_value"), tags$td("各时段"), tags$td("Minimum Value"), tags$td("最小值 (仅基于真实测量值)")),
                                                             tags$tr(tags$td("Delta"), tags$td("各时段"), tags$td("Range (Max - Min)"), tags$td("波动范围 (仅基于真实测量值)")),
                                                             tags$tr(tags$td("AUC / Sd"), tags$td("各时段"), tags$td("Area Under Curve"), tags$td("总曲线下面积 (等于 Sd)")),
                                                             tags$tr(tags$td("Ts1_total"), tags$td("各时段"), tags$td("Time Over Upper Limit"), tags$td("高于上限总时间 (分钟)")),
                                                             tags$tr(tags$td("Ts2_total"), tags$td("各时段"), tags$td("Time Within Range"), tags$td("目标范围内总时间 (分钟)")),
                                                             tags$tr(tags$td("Ts3_total"), tags$td("各时段"), tags$td("Time Below Lower Limit"), tags$td("低于下限总时间 (分钟)")),
                                                             tags$tr(tags$td("Sa"), tags$td("各时段"), tags$td("Area above Upper Limit"), tags$td("高值曲线下面积(计算用)")),
                                                             tags$tr(tags$td("Sc"), tags$td("各时段"), tags$td("Area below Lower Limit"), tags$td("低值与下限间面积(计算用)")),
                                                             tags$tr(tags$td("Se"), tags$td("各时段"), tags$td("Rectangular Area for Hyper"), tags$td("高值时间矩形面积(计算用)")),
                                                             tags$tr(tags$td("Sf"), tags$td("各时段"), tags$td("Rectangular Area for Hypo"), tags$td("低值时间矩形面积(计算用)"))
                                                           ) # End tbody
                                                ) # End table
                                            ) # End scrollable div
                                        ) # End panel-body
                                    ), # End panel-default (Instructions)
                                    
                                    # Author Information (Unchanged)
                                    div(class = "panel panel-info", style="margin-top: 20px;",
                                        div(class = "panel-heading", style="text-align: center;",
                                            h5(icon("user-md"), "关于作者与版本", style = "margin: 5px 0;")
                                        ),
                                        div(class = "panel-body", style = "text-align: center; font-size: 0.95em;",
                                            p(strong("李谟然 (Moran Li)")),
                                            p("同济大学医学院 临床医学硕士；上海市第十人民医院 医师"),
                                            p(style="color: #666;", "应用版本: 1.0.0 (中文版，更新于 2024年4月17日)"), # Update version/date
                                            p("联系方式/反馈建议：", a("morethanlee@163.com", href = "mailto:morethanlee@163.com"))
                                        )
                                    ) # End panel-info (Author)
                                    
                             ) # End column(12)
                           ) # End fluidRow for help content
                  ) # End tabPanel "使用说明"
                  
      ) # End main tabsetPanel
    ) # End mainPanel
  ), # End sidebarLayout
  
  # --- Footer (Unchanged) ---
  tags$footer(
    style = "text-align: center; padding: 15px; background-color: #f5f5f5; margin-top: 30px; border-top: 1px solid #ddd; font-size: 0.9em; color: #555;",
    div("版权所有",icon("copyright"), " 2024 | 李谟然 知心智医工作室 | 保留所有权利"), # Updated Year
    div("如有任何建议或反馈，请联系: ", a("morethanlee@163.com", href = "mailto:morethanlee@163.com"))
  ) # End Footer
  
) # End fluidPage


# --- 4. Server Logic (MODIFIED FOR 24H SEGMENTED CALCULATION & UI RENDERING) ---
server <- function(input, output, session) {
  
  # --- Reactive Values (Added '24h_segmented' key) ---
  values <- reactiveValues(
    raw_data_input = NULL,
    prepared_long_data = NULL,
    wide_dfs = list(),
    individual_series = list(),
    interpolated_dfs = list(),
    sorted_times = NULL,
    sorted_minutes = NULL,
    split_data_wide = list(),
    metric_results = list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()), # Added key
    processing_error = NULL,
    calculation_error = NULL,
    data_processed_successfully = FALSE,
    metrics_calculated_successfully = FALSE,
    data_source_msg = "无数据加载",
    targets_used_day = list(),
    targets_used_night = list(),
    targets_used_24h = list(), # Targets for the unified 24h calculation
    # Note: targets_used_day/night will be used for the segmented 24h calculation
    available_patients_viz = character(0),
    selected_patient_viz = NULL,
    selected_metric_viz = "SBP",
    targets_locked = FALSE,
    locked_targets = NULL
  )

  # --- Target-range state helpers ---
  # Keep every target input in one place so the lock button controls the full
  # target set consistently (including PP/MAP), rather than only the two
  # calculation shortcut buttons.
  TARGET_INPUT_IDS <- unlist(lapply(c("sbp", "dbp", "hr", "pp", "map"), function(metric_name) {
    unlist(lapply(c("day", "night", "24h"), function(period_name) {
      paste0(metric_name, "_", period_name, "_", c("lower", "upper"))
    }), use.names = FALSE)
  }), use.names = FALSE)

  read_current_targets <- function() {
    list(
      sbp_day_lower = input$sbp_day_lower, sbp_day_upper = input$sbp_day_upper,
      dbp_day_lower = input$dbp_day_lower, dbp_day_upper = input$dbp_day_upper,
      hr_day_lower = input$hr_day_lower, hr_day_upper = input$hr_day_upper,
      pp_day_lower = input$pp_day_lower, pp_day_upper = input$pp_day_upper,
      map_day_lower = input$map_day_lower, map_day_upper = input$map_day_upper,
      sbp_night_lower = input$sbp_night_lower, sbp_night_upper = input$sbp_night_upper,
      dbp_night_lower = input$dbp_night_lower, dbp_night_upper = input$dbp_night_upper,
      hr_night_lower = input$hr_night_lower, hr_night_upper = input$hr_night_upper,
      pp_night_lower = input$pp_night_lower, pp_night_upper = input$pp_night_upper,
      map_night_lower = input$map_night_lower, map_night_upper = input$map_night_upper,
      sbp_24h_lower = input$sbp_24h_lower, sbp_24h_upper = input$sbp_24h_upper,
      dbp_24h_lower = input$dbp_24h_lower, dbp_24h_upper = input$dbp_24h_upper,
      hr_24h_lower = input$hr_24h_lower, hr_24h_upper = input$hr_24h_upper,
      pp_24h_lower = input$pp_24h_lower, pp_24h_upper = input$pp_24h_upper,
      map_24h_lower = input$map_24h_lower, map_24h_upper = input$map_24h_upper
    )
  }

  target_is_missing <- function(x) {
    length(x) == 0L || (length(x) == 1L && is.na(x))
  }

  target_is_finite_number <- function(x) {
    length(x) == 1L && is.numeric(x) && !is.na(x) && is.finite(x)
  }

  validate_optional_target_pairs <- function(targets) {
    period_labels <- c(day = "日间", night = "夜间", `24h` = "24h日夜统一")
    for (metric_name in c("pp", "map")) {
      for (period_name in names(period_labels)) {
        lower <- targets[[paste0(metric_name, "_", period_name, "_lower")]]
        upper <- targets[[paste0(metric_name, "_", period_name, "_upper")]]
        lower_missing <- target_is_missing(lower)
        upper_missing <- target_is_missing(upper)
        label <- paste(period_labels[[period_name]], toupper(metric_name))

        if (xor(lower_missing, upper_missing)) {
          return(list(
            valid = FALSE,
            message = paste0(label, " 为可选范围，但下限和上限必须同时填写或同时留空。")
          ))
        }
        if (!lower_missing &&
            (!target_is_finite_number(lower) || !target_is_finite_number(upper))) {
          return(list(valid = FALSE, message = paste0(label, " 的上下限必须是有效数字。")))
        }
      }
    }
    list(valid = TRUE, message = NULL)
  }

  validate_target_snapshot <- function(targets) {
    required_names <- grep("^(sbp|dbp|hr)_.*_(lower|upper)$", names(targets), value = TRUE)
    invalid_required <- vapply(targets[required_names], function(x) {
      length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x)
    }, logical(1))
    if (any(invalid_required)) {
      return(list(valid = FALSE, message = "SBP、DBP、HR 的所有目标范围必须是有效数字后才能锁定。"))
    }

    optional_names <- grep("^(pp|map)_.*_(lower|upper)$", names(targets), value = TRUE)
    invalid_optional <- vapply(targets[optional_names], function(x) {
      length(x) > 1L || (length(x) == 1L && !is.na(x) && (!is.numeric(x) || !is.finite(x)))
    }, logical(1))
    if (any(invalid_optional)) {
      return(list(valid = FALSE, message = "PP、MAP 目标范围如已填写，必须是有效数字后才能锁定。"))
    }

    optional_pair_validation <- validate_optional_target_pairs(targets)
    if (!isTRUE(optional_pair_validation$valid)) return(optional_pair_validation)

    period_labels <- c(day = "日间", night = "夜间", `24h` = "24h日夜统一")
    for (metric_name in c("sbp", "dbp", "hr", "pp", "map")) {
      for (period_name in names(period_labels)) {
        lower <- targets[[paste0(metric_name, "_", period_name, "_lower")]]
        upper <- targets[[paste0(metric_name, "_", period_name, "_upper")]]
        if (length(lower) == 1L && length(upper) == 1L &&
            is.numeric(lower) && !is.na(lower) && is.numeric(upper) && !is.na(upper) && upper <= lower) {
          label <- paste(period_labels[[period_name]], toupper(metric_name))
          return(list(valid = FALSE, message = paste0(label, " 的目标范围上限必须大于下限后才能锁定。")))
        }
      }
    }

    list(valid = TRUE, message = NULL)
  }

  set_target_controls_locked <- function(locked) {
    for (target_id in TARGET_INPUT_IDS) {
      if (isTRUE(locked)) shinyjs::disable(target_id) else shinyjs::enable(target_id)
    }

    if (isTRUE(locked)) {
      shinyjs::disable("apply_targets_btn")
      shinyjs::disable("preset_targets")
      updateActionButton(session, "save_custom_targets_btn", label = "解除目标范围锁定", icon = icon("unlock"))
    } else {
      shinyjs::enable("apply_targets_btn")
      shinyjs::enable("preset_targets")
      updateActionButton(session, "save_custom_targets_btn", label = "保存并锁定自定义范围", icon = icon("lock"))
    }
  }
  
  # --- Placeholder Variability Reference Values (Unchanged) ---
  VARIABILITY_REFERENCE_VALUES <- list(
    "SBP" = list(sd = 15, arv = 12),
    "DBP" = list(sd = 12, arv = 10),
    "HR" = list(sd = 10, arv = 8),
    "PP" = list(sd = 8, arv = 6), # Example values, adjust as needed
    "MAP" = list(sd = 10, arv = 8) # Example values, adjust as needed
  )
  
  # --- Data Loading Logic (Reset added '24h_segmented' key) ---
  observe({
    file <- input$file1
    use_builtin <- input$use_builtin_data
    
    # Reset states when input source changes
    values$prepared_long_data <- NULL; values$wide_dfs <- list(); values$individual_series <- list(); values$interpolated_dfs <- list();
    values$split_data_wide <- list(); values$processing_error <- NULL; values$calculation_error <- NULL;
    values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()); # Reset new key
    values$data_processed_successfully <- FALSE
    values$metrics_calculated_successfully <- FALSE
    values$available_patients_viz <- character(0)
    values$selected_patient_viz <- NULL
    values$targets_locked <- FALSE # Reset lock state
    values$locked_targets <- NULL
    shinyjs::disable("calculate_metrics_btn")
    shinyjs::disable("save_custom_targets_btn") # Disable lock button too
    set_target_controls_locked(FALSE)
    
    
    # Load data based on input
    if (!use_builtin && !is.null(file)) {
      showNotification("检测到文件输入...", type = "message", duration = 2)
      tryCatch({
        df <- tryCatch(read.csv(file$datapath, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL", " "), fileEncoding = "UTF-8-BOM"),
                       error = function(e1) {
                         warning("读取 CSV 文件时 UTF-8 编码失败，尝试系统默认编码...", call. = FALSE)
                         tryCatch(read.csv(file$datapath, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL", " ")),
                                  error = function(e2){ stop(paste("无法以 UTF-8 或系统默认编码读取文件:", e2$message)) })
                       })
        if (!is.data.frame(df) || nrow(df) == 0) { stop("CSV 文件为空或格式不正确。") }
        values$raw_data_input <- df
        values$data_source_msg <- paste("来自文件:", file$name)
        showNotification("文件数据已加载。", type = "message", duration = 3)
        updateCheckboxInput(session, "use_builtin_data", value = FALSE)
      }, error = function(e) {
        error_msg <- paste("加载文件失败:", e$message)
        showNotification(error_msg, type = "error", duration = NULL)
        values$raw_data_input <- NULL
        values$data_source_msg <- "文件加载失败"
        values$processing_error <- error_msg
      })
    } else if (use_builtin) {
      showNotification("加载内置示例数据...", type = "message", duration = 2)
      tryCatch({
        # Use the reduced dataset string
        df <- read.csv(text = csv_data_string, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL", " "))
        if (!is.data.frame(df) || nrow(df) == 0) { stop("内置 CSV 字符串为空或格式不正确。") }
        values$raw_data_input <- df
        values$data_source_msg <- "来自内置示例数据 (P001-P002)"
        showNotification("示例数据已加载。", type = "message", duration = 3)
      }, error = function(e) {
        error_msg <- paste("加载内置数据失败:", e$message)
        showNotification(error_msg, type = "error", duration = NULL)
        values$raw_data_input <- NULL
        values$data_source_msg <- "内置数据加载失败"
        values$processing_error <- error_msg
      })
    } else {
      values$raw_data_input <- NULL
      values$data_source_msg <- "请选择文件或勾选使用内置数据"
    }
  })
  observeEvent(input$use_builtin_data, {
    if (input$use_builtin_data) {
      # Reset states
      values$prepared_long_data <- NULL; values$wide_dfs <- list(); values$individual_series <- list(); values$interpolated_dfs <- list();
      values$split_data_wide <- list(); values$processing_error <- NULL; values$calculation_error <- NULL;
      values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()); # Reset new key
      values$data_processed_successfully <- FALSE
      values$metrics_calculated_successfully <- FALSE
      values$available_patients_viz <- character(0)
      values$selected_patient_viz <- NULL
      values$targets_locked <- FALSE # Reset lock state
      values$locked_targets <- NULL
      shinyjs::disable("calculate_metrics_btn")
      shinyjs::disable("save_custom_targets_btn")
      set_target_controls_locked(FALSE)
      
      showNotification("加载内置示例数据...", type = "message", duration = 2)
      tryCatch({
        # Use the reduced dataset string
        df <- read.csv(text = csv_data_string, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL", " "))
        if (!is.data.frame(df) || nrow(df) == 0) stop("内置数据无效。")
        values$raw_data_input <- df
        values$data_source_msg <- "来自内置示例数据 (P001-P002)"
        showNotification("示例数据已加载。", type = "message", duration = 3)
      }, error = function(e) {
        error_msg <- paste("加载内置数据失败:", e$message)
        showNotification(error_msg, type = "error", duration = NULL)
        values$raw_data_input <- NULL
        values$data_source_msg <- "内置数据加载失败"
        values$processing_error <- error_msg
      })
    }
  }, ignoreInit = TRUE)
  
  
  # --- UI Rendering for Data Tables (Unchanged) ---
  output$data_source_title <- renderText({ paste("当前数据预览 (来源:", values$data_source_msg, ")") })
  output$raw_data_table <- renderDT({ req(values$raw_data_input); datatable(head(values$raw_data_input, 200), caption="原始输入数据预览 (最多显示200行)", options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 20)), rownames = FALSE) })
  output$prepared_long_table <- renderDT({ req(values$prepared_long_data); datatable(values$prepared_long_data, caption="处理和验证后的长格式数据", options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top') })
  output$wide_data_tabs <- renderUI({
    req(values$data_processed_successfully, length(values$wide_dfs) > 0)
    metrics_available <- names(values$wide_dfs)
    if (length(metrics_available) == 0) return(p("没有可显示的宽格式数据。"))
    metric_tabs <- lapply(metrics_available, function(metric) { tabPanel(title = metric, DTOutput(paste0("wide_", tolower(metric), "_table"))) })
    do.call(tabsetPanel, c(metric_tabs, id = "wide_data_subtabs"))
  })
  observe({
    req(values$data_processed_successfully, length(values$wide_dfs) > 0)
    metrics_available <- names(values$wide_dfs)
    lapply(metrics_available, function(metric) {
      output[[paste0("wide_", tolower(metric), "_table")]] <- renderDT({
        req(values$wide_dfs[[metric]])
        datatable(values$wide_dfs[[metric]], caption = paste0("宽格式数据 (插补前) - ", metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })
    })
  })
  output$interpolated_data_tabs <- renderUI({
    req(values$data_processed_successfully, length(values$interpolated_dfs) > 0)
    metrics_available <- names(values$interpolated_dfs)
    if (length(metrics_available) == 0) return(p("没有可显示的插补后宽格式数据。"))
    metric_tabs <- lapply(metrics_available, function(metric) { tabPanel(title = metric, DTOutput(paste0("interp_", tolower(metric), "_table"))) })
    do.call(tabsetPanel, c(metric_tabs, id = "interp_data_subtabs"))
  })
  observe({
    req(values$data_processed_successfully, length(values$interpolated_dfs) > 0)
    metrics_available <- names(values$interpolated_dfs)
    lapply(metrics_available, function(metric) {
      output[[paste0("interp_", tolower(metric), "_table")]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        datatable(values$interpolated_dfs[[metric]], caption = paste0("插补后宽格式数据 (原始时间) - ", metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })
    })
  })
  output$full_24h_interpolated_data_tabs <- renderUI({
    req(values$data_processed_successfully, length(values$interpolated_dfs) > 0)
    metrics_available <- names(values$interpolated_dfs)
    if (length(metrics_available) == 0) return(p("没有可显示的24小时整体插补后数据。"))
    metric_tabs <- lapply(metrics_available, function(metric) { output_id <- paste0("full_interp_", tolower(metric), "_table"); tabPanel(title = metric, DTOutput(output_id)) })
    do.call(tabsetPanel, c(metric_tabs, id = "full_interp_data_subtabs_split"))
  })
  observe({
    req(values$data_processed_successfully, length(values$interpolated_dfs) > 0)
    metrics_available <- names(values$interpolated_dfs)
    lapply(metrics_available, function(metric) {
      output_id <- paste0("full_interp_", tolower(metric), "_table")
      output[[output_id]] <- renderDT({
        req(values$interpolated_dfs[[metric]])
        datatable(values$interpolated_dfs[[metric]], caption = paste0("24h 整体插补数据 - ", metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
      })
    })
  })
  render_split_metric_tabs <- function(period_name) {
    renderUI({
      req(values$data_processed_successfully, length(values$split_data_wide) > 0, !is.null(values$split_data_wide[[period_name]]))
      metrics_available <- names(values$split_data_wide[[period_name]])
      if (length(metrics_available) == 0) return(p(paste("没有", period_name, "时段的数据。")))
      metric_tabs <- lapply(metrics_available, function(metric) { output_id <- paste0("split_", period_name, "_", tolower(metric), "_table"); tabPanel(title = metric, DTOutput(output_id)) })
      do.call(tabsetPanel, c(metric_tabs, id = paste0("split_metric_subtabs_", period_name)))
    })
  }
  output$split_day0_night_metric_tabs <- render_split_metric_tabs("day0_night")
  output$split_day1_day_metric_tabs   <- render_split_metric_tabs("day1_day")
  output$split_day1_night_metric_tabs <- render_split_metric_tabs("day1_night")
  output$split_day2_day_metric_tabs   <- render_split_metric_tabs("day2_day")
  observe({
    req(values$data_processed_successfully, length(values$split_data_wide) > 0)
    for (period_name in names(values$split_data_wide)) {
      if (!is.null(values$split_data_wide[[period_name]])) {
        metrics_in_period <- names(values$split_data_wide[[period_name]])
        for (metric in metrics_in_period) {
          local({
            current_period <- period_name; current_metric <- metric
            output_id <- paste0("split_", current_period, "_", tolower(current_metric), "_table")
            output[[output_id]] <- renderDT({
              req(values$split_data_wide[[current_period]][[current_metric]])
              period_title <- switch(current_period, "day0_night" = "Day 0 Night", "day1_day" = "Day 1 Day", "day1_night" = "Day 1 Night", "day2_day" = "Day 2 Day", current_period)
              datatable(values$split_data_wide[[current_period]][[current_metric]], caption = paste0(period_title, " - ", current_metric), options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE, filter='top')
            })
          })
        }
      }
    }
  })
  
  # --- Time Presets (Unchanged) ---
  observeEvent(input$preset_east_asia, {
    updateNumericInput(session, "day1_start_h", value = 5); updateNumericInput(session, "day1_start_m", value = 0)
    updateNumericInput(session, "day1_night_start_h", value = 20); updateNumericInput(session, "day1_night_start_m", value = 0)
    updateNumericInput(session, "day2_start_h", value = 5); updateNumericInput(session, "day2_start_m", value = 0)
    updateNumericInput(session, "day2_night_start_h", value = 20); updateNumericInput(session, "day2_night_start_m", value = 0)
    showNotification("时间已预设为：日间 05:00 - 19:59, 夜间 20:00 - 次日 04:59", type = "message")
  })
  observeEvent(input$preset_western, {
    updateNumericInput(session, "day1_start_h", value = 7); updateNumericInput(session, "day1_start_m", value = 0)
    updateNumericInput(session, "day1_night_start_h", value = 22); updateNumericInput(session, "day1_night_start_m", value = 0)
    updateNumericInput(session, "day2_start_h", value = 7); updateNumericInput(session, "day2_start_m", value = 0)
    updateNumericInput(session, "day2_night_start_h", value = 22); updateNumericInput(session, "day2_night_start_m", value = 0)
    showNotification("时间已预设为：日间 07:00 - 21:59, 夜间 22:00 - 次日 06:59", type = "message")
  })
  
  # --- Target Range Logic (kept identical to the original implementation) ---
  calculate_derived_limits <- function(sbp_l, sbp_u, dbp_l, dbp_u) {
    pp_l <- NA_real_; pp_u <- NA_real_; map_l <- NA_real_; map_u <- NA_real_
    # Only calculate if all four base inputs are valid numerics
    if (is.numeric(sbp_l) && is.numeric(sbp_u) && is.numeric(dbp_l) && is.numeric(dbp_u) &&
        !is.na(sbp_l)&& !is.na(sbp_u) && !is.na(dbp_l) && !is.na(dbp_u)) {
      # Check for valid ranges (upper >= lower)
      if (sbp_u >= sbp_l && dbp_u >= dbp_l) {
        pp_l <- sbp_l - dbp_u # Min PP = Min SBP - Max DBP
        pp_u <- sbp_u - dbp_l # Max PP = Max SBP - Min DBP
        map_l <- dbp_l + (1/3) * (sbp_l - dbp_l) # Min MAP uses min values
        map_u <- dbp_u + (1/3) * (sbp_u - dbp_u) # Max MAP uses max values (approximation)
        
        # Ensure lower <= upper after calculation
        if(!is.na(pp_l) && !is.na(pp_u) && pp_l > pp_u) { temp_pp = pp_l; pp_l = pp_u; pp_u = temp_pp; }
        if(!is.na(map_l) && !is.na(map_u) && map_l > map_u) { temp_map = map_l; map_l = map_u; map_u = temp_map; }
        
        # Round results
        pp_l <- round(pp_l, 1); pp_u <- round(pp_u, 1); map_l <- round(map_l, 1); map_u <- round(map_u, 1)
      } else {
        warning("不能计算PP/MAP范围，因为SBP或DBP的上限小于下限。", call. = FALSE)
      }
    }
    return(list(pp_l = pp_l, pp_u = pp_u, map_l = map_l, map_u = map_u))
  }
  
  # Update PP/MAP based on SBP/DBP ranges *only if targets are NOT locked*
  observeEvent(input$apply_targets_btn, {
    if (isTRUE(values$targets_locked)) {
      showNotification("自定义目标范围已锁定，无法自动更新 PP/MAP。", type = "warning", duration = 5)
      return()
    }
    targets_now <- isolate(read_current_targets())
    period_labels <- c(day = "日间", night = "夜间", `24h` = "24h日夜统一")
    derived_by_period <- list()

    # Validate all three SBP/DBP pairs before writing any PP/MAP input. This
    # prevents a partially updated target state when one period is incomplete.
    for (period_name in names(period_labels)) {
      sbp_l <- targets_now[[paste0("sbp_", period_name, "_lower")]]
      sbp_u <- targets_now[[paste0("sbp_", period_name, "_upper")]]
      dbp_l <- targets_now[[paste0("dbp_", period_name, "_lower")]]
      dbp_u <- targets_now[[paste0("dbp_", period_name, "_upper")]]
      base_values <- c(sbp_l, sbp_u, dbp_l, dbp_u)

      if (length(base_values) != 4L || any(!is.finite(base_values))) {
        showNotification(
          paste0("无法自动计算：", period_labels[[period_name]], "的 SBP/DBP 上下限必须全部填写为有效数字。"),
          type = "error", duration = 7
        )
        return()
      }
      if (sbp_u <= sbp_l || dbp_u <= dbp_l) {
        showNotification(
          paste0("无法自动计算：", period_labels[[period_name]], "的 SBP/DBP 上限必须大于下限。"),
          type = "error", duration = 7
        )
        return()
      }
      derived_by_period[[period_name]] <- calculate_derived_limits(sbp_l, sbp_u, dbp_l, dbp_u)
    }

    for (period_name in names(derived_by_period)) {
      derived <- derived_by_period[[period_name]]
      updateNumericInput(session, paste0("pp_", period_name, "_lower"), value = derived$pp_l)
      updateNumericInput(session, paste0("pp_", period_name, "_upper"), value = derived$pp_u)
      updateNumericInput(session, paste0("map_", period_name, "_lower"), value = derived$map_l)
      updateNumericInput(session, paste0("map_", period_name, "_upper"), value = derived$map_u)
    }

    showNotification(
      "三套 PP/MAP 范围已根据各自的 SBP/DBP 范围更新；HR范围保持不变。",
      type = "message", duration = 5
    )
    
  }, ignoreInit = TRUE)
  
  # Apply Default Targets *only if targets are NOT locked*
  observeEvent(input$preset_targets, {
    if (isTRUE(values$targets_locked)) {
      showNotification("自定义目标范围已锁定，无法应用预设。", type = "warning", duration = 5)
      return()
    }
    updateNumericInput(session, "sbp_day_lower", value = 90); updateNumericInput(session, "sbp_day_upper", value = 120)
    updateNumericInput(session, "dbp_day_lower", value = 55); updateNumericInput(session, "dbp_day_upper", value = 70)
    updateNumericInput(session, "hr_day_lower", value = 60); updateNumericInput(session, "hr_day_upper", value = 100)
    updateNumericInput(session, "sbp_night_lower", value = 90); updateNumericInput(session, "sbp_night_upper", value = 110)
    updateNumericInput(session, "dbp_night_lower", value = 55); updateNumericInput(session, "dbp_night_upper", value = 60)
    updateNumericInput(session, "hr_night_lower", value = 50); updateNumericInput(session, "hr_night_upper", value = 90)
    updateNumericInput(session, "sbp_24h_lower", value = 90); updateNumericInput(session, "sbp_24h_upper", value = 115)
    updateNumericInput(session, "dbp_24h_lower", value = 55); updateNumericInput(session, "dbp_24h_upper", value = 65)
    updateNumericInput(session, "hr_24h_lower", value = 55); updateNumericInput(session, "hr_24h_upper", value = 95)
    
    # Also calculate and update default PP/MAP based on these SBP/DBP defaults
    inputs <- list( sbp_d_l = 90, sbp_d_u = 120, dbp_d_l = 55, dbp_d_u = 70, sbp_n_l = 90, sbp_n_u = 110, dbp_n_l = 55, dbp_n_u = 60, sbp_24_l = 90, sbp_24_u = 115, dbp_24_l = 55, dbp_24_u = 65 )
    day_derived <- calculate_derived_limits(inputs$sbp_d_l, inputs$sbp_d_u, inputs$dbp_d_l, inputs$dbp_d_u)
    updateNumericInput(session, "pp_day_lower", value = day_derived$pp_l); updateNumericInput(session, "pp_day_upper", value = day_derived$pp_u)
    updateNumericInput(session, "map_day_lower", value = day_derived$map_l); updateNumericInput(session, "map_day_upper", value = day_derived$map_u)
    night_derived <- calculate_derived_limits(inputs$sbp_n_l, inputs$sbp_n_u, inputs$dbp_n_l, inputs$dbp_n_u)
    updateNumericInput(session, "pp_night_lower", value = night_derived$pp_l); updateNumericInput(session, "pp_night_upper", value = night_derived$pp_u)
    updateNumericInput(session, "map_night_lower", value = night_derived$map_l); updateNumericInput(session, "map_night_upper", value = night_derived$map_u)
    `24h_derived` <- calculate_derived_limits(inputs$sbp_24_l, inputs$sbp_24_u, inputs$dbp_24_l, inputs$dbp_24_u)
    updateNumericInput(session, "pp_24h_lower", value = `24h_derived`$pp_l); updateNumericInput(session, "pp_24h_upper", value = `24h_derived`$pp_u)
    updateNumericInput(session, "map_24h_lower", value = `24h_derived`$map_l); updateNumericInput(session, "map_24h_upper", value = `24h_derived`$map_u)
    
    showNotification("已应用默认的目标范围 (SBP, DBP, HR, 以及计算出的 PP/MAP)。", type = "message", duration = 5)
  })
  
  # --- Save/unlock custom target ranges ---
  observeEvent(input$save_custom_targets_btn, {
    if (isTRUE(values$targets_locked)) {
      values$targets_locked <- FALSE
      values$locked_targets <- NULL
      set_target_controls_locked(FALSE)
      showNotification("已解除目标范围锁定；当前阈值已保留，可以继续修改、自动计算或应用预设。", type = "message", duration = 5)
      return()
    }

    targets_to_lock <- isolate(read_current_targets())
    validation <- validate_target_snapshot(targets_to_lock)
    if (!isTRUE(validation$valid)) {
      showNotification(validation$message, type = "error", duration = 7)
      return()
    }

    # Store an immutable snapshot. Metric calculation reads this snapshot while
    # locked, so browser-side changes cannot silently alter the calculation.
    values$locked_targets <- targets_to_lock
    values$targets_locked <- TRUE
    set_target_controls_locked(TRUE)
    showNotification("自定义目标范围已保存并锁定。计算指标时将使用这份快照。", type = "message", duration = 5)
  }, ignoreInit = TRUE)
  
  
  # --- Data Processing Logic (Reset added '24h_segmented' key) ---
  observeEvent(input$process_data_btn, {
    # Reset downstream states
    values$prepared_long_data <- NULL; values$wide_dfs <- list(); values$individual_series <- list(); values$interpolated_dfs <- list();
    values$sorted_times <- NULL; values$sorted_minutes <- NULL; values$split_data_wide <- list();
    values$processing_error <- NULL; values$calculation_error <- NULL;
    values$data_processed_successfully <- FALSE
    values$metrics_calculated_successfully <- FALSE
    values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()); # Reset new key
    values$targets_used_day <- list(); values$targets_used_night <- list(); values$targets_used_24h <- list();
    values$available_patients_viz <- character(0)
    values$selected_patient_viz <- NULL
    # Reset lock state and button appearance
    values$targets_locked <- FALSE
    values$locked_targets <- NULL
    shinyjs::disable("calculate_metrics_btn")
    shinyjs::disable("save_custom_targets_btn") # Disable lock button initially
    set_target_controls_locked(FALSE)
    
    req(values$raw_data_input)
    
    d1s_h <- input$day1_start_h;     d1s_m <- input$day1_start_m
    d1n_h <- input$day1_night_start_h; d1n_m <- input$day1_night_start_m
    d2s_h <- input$day2_start_h;     d2s_m <- input$day2_start_m
    d2n_h <- input$day2_night_start_h; d2n_m <- input$day2_night_start_m
    
    # Validate time inputs
    time_inputs_h <- c(d1s_h, d1n_h, d2s_h, d2n_h)
    time_inputs_m <- c(d1s_m, d1n_m, d2s_m, d2n_m)
    if(any(sapply(time_inputs_h, function(x) !is.numeric(x) || is.na(x) || x < 0 || x > 23 || x != floor(x) )) ||
       any(sapply(time_inputs_m, function(x) !is.numeric(x) || is.na(x) || x < 0 || x > 59 || x != floor(x) ))) {
      error_msg <- "错误：日间/夜间 小时(0-23)和分钟(0-59) 必须是有效的整数。"
      showNotification(error_msg, type="error", duration=7)
      values$processing_error <- error_msg
      shinyjs::enable("process_data_btn") # Re-enable process button on error
      return()
    }
    d1_start_total_min = d1s_h * 60 + d1s_m
    d1_night_start_total_min = d1n_h * 60 + d1n_m
    d2_start_total_min_in_day = d2s_h * 60 + d2s_m
    d2_night_start_total_min_in_day = d2n_h * 60 + d2n_m
    if (d1_night_start_total_min == d1_start_total_min || d2_night_start_total_min_in_day == d2_start_total_min_in_day) {
      showNotification("警告：同一天的日间和夜间开始时间不能相同。请检查时间设置。", type="warning", duration=7)
      # Allow processing to continue, but warn user
    }
    
    shinyjs::disable("process_data_btn")
    shinyjs::disable("calculate_metrics_btn") # Keep these disabled
    shinyjs::disable("save_custom_targets_btn")
    
    withProgress(message = '处理数据...', value = 0, {
      tryCatch({
        incProgress(0.1, detail = "数据校验与准备...")
        long_prep <- load_and_prepare_data(values$raw_data_input)
        if (is.null(long_prep) || !is.data.frame(long_prep) || nrow(long_prep) == 0) stop("数据准备步骤未能生成有效数据。")
        values$prepared_long_data <- long_prep
        incProgress(0.2, detail = "准备完成")
        
        incProgress(0.1, detail = "创建宽格式(插补前)...")
        wide_result <- create_wide_data_per_metric(values$prepared_long_data,
                                                   d1s_h, d1s_m, d1n_h, d1n_m,
                                                   d2s_h, d2s_m, d2n_h, d2n_m)
        # Preserve the source-code wide-table pages exactly. These union-axis
        # tables are display artifacts only and are never used for metrics.
        values$wide_dfs <- wide_result$wide_dfs
        if (length(values$wide_dfs) == 0) stop("未能为任何指标创建宽格式数据（插补前）。")
        incProgress(0.2, detail = "宽格式(插补前)创建完成")
        
        incProgress(0.1, detail = "逐患者建立独立时间轴并插补必要边界...")
        values$individual_series <- create_individual_patient_series(
          values$prepared_long_data,
          d1s_h, d1s_m, d1n_h, d1n_m,
          d2s_h, d2s_m, d2n_h, d2n_m
        )
        # Rebuild a union-shaped table solely for the original interpolation
        # and split-data subpages. Calculations read values$individual_series.
        individual_wide <- individual_series_to_wide(values$individual_series)
        values$interpolated_dfs <- individual_wide$wide_dfs
        values$sorted_times <- individual_wide$sorted_times
        values$sorted_minutes <- individual_wide$sorted_minutes
        if (length(values$interpolated_dfs) == 0) stop("未能为任何指标生成插补后的宽格式数据。")
        incProgress(0.2, detail = "逐患者时间轴处理完成")
        
        incProgress(0.1, detail = "分割插补后宽数据时段...")
        split_result_wide <- split_wide_data_day_night(values$interpolated_dfs, values$sorted_times, values$sorted_minutes,
                                                       d1s_h, d1s_m, d1n_h, d1n_m,
                                                       d2s_h, d2s_m, d2n_h, d2n_m)
        values$split_data_wide <- split_result_wide
        incProgress(0.1, detail = "数据分割完成")
        
        values$data_processed_successfully <- TRUE
        values$processing_error <- NULL
        shinyjs::enable("calculate_metrics_btn")
        shinyjs::enable("save_custom_targets_btn") # Enable lock button after successful processing
        showNotification("数据处理完成！现在可以设置目标范围、锁定自定义范围或计算指标。", type = "message", duration = 5) # Updated message
        updateTabsetPanel(session, "main_tabset", selected = "processed_data_tab")
        
      }, error = function(e) {
        values$processing_error <- e$message
        values$data_processed_successfully <- FALSE
        showNotification(paste("数据处理失败:", e$message), type = "error", duration = NULL)
        values$prepared_long_data <- NULL; values$wide_dfs <- list(); values$individual_series <- list(); values$interpolated_dfs <- list();
        values$split_data_wide <- list();
        shinyjs::disable("calculate_metrics_btn")
        shinyjs::disable("save_custom_targets_btn") # Keep disabled on error
      }, finally = {
        shinyjs::enable("process_data_btn") # Always re-enable process button
      })
    })
  })
  
  
  # --- Metric Calculation Function (Calculates Day, Night, 24h-unified, AND 24h-segmented) ---
  perform_metric_calculation <- function() {
    # Reset calculation-specific states
    values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()) # Reset all results
    values$calculation_error <- NULL;
    values$metrics_calculated_successfully <- FALSE
    values$targets_used_day <- list(); values$targets_used_night <- list(); values$targets_used_24h <- list();
    values$available_patients_viz <- character(0)
    values$selected_patient_viz <- NULL
    
    # Check prerequisites
    req(values$data_processed_successfully,
        values$prepared_long_data,
        length(values$individual_series) > 0)
    
    # Use the saved snapshot while locked; otherwise read the current UI values.
    all_targets <- isolate({
      if (isTRUE(values$targets_locked) && !is.null(values$locked_targets)) {
        values$locked_targets
      } else {
        read_current_targets()
      }
    })
    
    # Target validation (Essential: SBP/DBP/HR must be numeric, Optional: PP/MAP can be NA or numeric)
    required_target_names <- grep("^(sbp|dbp|hr)_.*_(lower|upper)$", names(all_targets), value = TRUE)
    required_targets <- all_targets[required_target_names]
    if(any(sapply(required_targets, function(x) !is.numeric(x) || is.na(x) || !is.finite(x)))) {
      error_msg <- "错误：SBP, DBP, HR 的所有目标范围必须是有效的数字才能计算。";
      showNotification(error_msg, type="error", duration=7); values$calculation_error <- error_msg; return()
    }
    
    optional_target_names <- grep("^(pp|map)_.*_(lower|upper)$", names(all_targets), value = TRUE)
    optional_targets <- all_targets[optional_target_names]
    if(any(sapply(optional_targets, function(x) !is.na(x) && (!is.numeric(x) || !is.finite(x))))) {
      error_msg <- "错误：如果 PP/MAP 目标范围被填写，则必须是有效的数字。";
      showNotification(error_msg, type="error", duration=7); values$calculation_error <- error_msg; return()
    }

    optional_pair_validation <- validate_optional_target_pairs(all_targets)
    if (!isTRUE(optional_pair_validation$valid)) {
      error_msg <- paste0("错误：", optional_pair_validation$message)
      showNotification(error_msg, type = "error", duration = 7)
      values$calculation_error <- error_msg
      return()
    }
    
    valid_limits <- TRUE
    check_limits <- function(lower, upper, label) {
      # Only check if BOTH limits are provided and numeric
      if (is.numeric(lower) && !is.na(lower) && is.numeric(upper) && !is.na(upper) && upper <= lower) {
        msg <- paste0("错误：", label, " 的目标范围上限 (", upper, ") 必须大于下限 (", lower, ") 才能计算。");
        showNotification(msg, type="error", duration=7); values$calculation_error <<- msg; return(FALSE)
      }
      return(TRUE)
    }
    limit_pairs <- list(
      list(all_targets$sbp_day_lower, all_targets$sbp_day_upper, "白天 SBP"), list(all_targets$dbp_day_lower, all_targets$dbp_day_upper, "白天 DBP"),
      list(all_targets$hr_day_lower, all_targets$hr_day_upper, "白天 HR"), list(all_targets$pp_day_lower, all_targets$pp_day_upper, "白天 PP"),
      list(all_targets$map_day_lower, all_targets$map_day_upper, "白天 MAP"), list(all_targets$sbp_night_lower, all_targets$sbp_night_upper, "夜晚 SBP"),
      list(all_targets$dbp_night_lower, all_targets$dbp_night_upper, "夜晚 DBP"), list(all_targets$hr_night_lower, all_targets$hr_night_upper, "夜晚 HR"),
      list(all_targets$pp_night_lower, all_targets$pp_night_upper, "夜晚 PP"), list(all_targets$map_night_lower, all_targets$map_night_upper, "夜晚 MAP"),
      list(all_targets$sbp_24h_lower, all_targets$sbp_24h_upper, "24h 统一 SBP"),
      list(all_targets$dbp_24h_lower, all_targets$dbp_24h_upper, "24h 统一 DBP"),
      list(all_targets$hr_24h_lower, all_targets$hr_24h_upper, "24h 统一 HR"),
      list(all_targets$pp_24h_lower, all_targets$pp_24h_upper, "24h 统一 PP"),
      list(all_targets$map_24h_lower, all_targets$map_24h_upper, "24h 统一 MAP")
    )
    for (pair in limit_pairs) { if (!check_limits(pair[[1]], pair[[2]], pair[[3]])) { valid_limits <- FALSE; break } }; if (!valid_limits) return()
    
    # Store the targets used for THIS calculation run
    values$targets_used_day <- all_targets[grep("_day_", names(all_targets))]
    values$targets_used_night <- all_targets[grep("_night_", names(all_targets))]
    values$targets_used_24h <- all_targets[grep("_24h_", names(all_targets))] # Store the unified 24h limits
    
    # Disable calculation button during calculation
    shinyjs::disable("calculate_metrics_btn")
    shinyjs::disable("save_custom_targets_btn") # Also disable lock button during calc
    
    target_source_text <- if (isTRUE(values$targets_locked)) "已锁定的目标范围快照" else "当前显示的目标范围"
    showNotification(paste0("开始计算指标 (使用", target_source_text, ")..."), type = "message", duration = 4)
    
    # Perform calculations with progress
    withProgress(message = '计算指标...', value = 0, {
      tryCatch({
        # The display-oriented wide tables may contain the union of all patient
        # timestamps. They are deliberately excluded from calculation.
        metrics_to_calculate <- names(values$individual_series)
        
        # Helper to get limits from the *just stored* targets
        get_limits_from_stored <- function(metric_name, period_suffix) {
          # Use correct list based on suffix ('24h' for unified 24h)
          stored_list <- switch(period_suffix, "day" = values$targets_used_day, "night" = values$targets_used_night, "24h" = values$targets_used_24h, list())
          lower_name <- paste0(tolower(metric_name), "_", period_suffix, "_lower")
          upper_name <- paste0(tolower(metric_name), "_", period_suffix, "_upper")
          lower_val <- if(lower_name %in% names(stored_list)) stored_list[[lower_name]] else NA_real_
          upper_val <- if(upper_name %in% names(stored_list)) stored_list[[upper_name]] else NA_real_
          
          if (!is.numeric(lower_val)) lower_val <- NA_real_
          if (!is.numeric(upper_val)) upper_val <- NA_real_
          
          list(lower = lower_val, upper = upper_val)
        }
        
        # --- Calculation Block ---
        
        # 1. 24-Hour Calculation (Unified Limits)
        incProgress(0.1, detail = "计算指标（24h日夜统一阈值）...")
        temp_results_24h <- list()
        for (metric in metrics_to_calculate) {
          limits <- get_limits_from_stored(metric, "24h") # Use '24h' suffix
          optional_without_limits <- tolower(metric) %in% c("pp", "map") &&
            is.na(limits$lower) && is.na(limits$upper)
          if (tolower(metric) %in% c("sbp", "dbp", "hr") && (is.na(limits$lower) || is.na(limits$upper))) {
            warning(paste("跳过 24h(统一) 计算必需指标", metric, "(上下限未完全设置)"), call.=FALSE); next
          }
          
          metric_result_df <- if (optional_without_limits) {
            calculate_abpm_metrics_without_limits_individual(
              values$individual_series[[metric]], "24h",
              isolate(input$day1_start_h), isolate(input$day1_start_m),
              isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
              isolate(input$day2_start_h), isolate(input$day2_start_m),
              isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
            )
          } else {
            calculate_abpm_metrics_for_period_individual(
              values$individual_series[[metric]], "24h", limits$upper, limits$lower,
              isolate(input$day1_start_h), isolate(input$day1_start_m),
              isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
              isolate(input$day2_start_h), isolate(input$day2_start_m),
              isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
            )
          }
          if (!is.null(metric_result_df) && nrow(metric_result_df) > 0 && ncol(metric_result_df) > 1) {
            cols_to_rename <- setdiff(colnames(metric_result_df), "MASKID")
            colnames(metric_result_df)[colnames(metric_result_df) %in% cols_to_rename] <- paste0(metric, "_", cols_to_rename)
            temp_results_24h[[metric]] <- metric_result_df
          } else { warning(paste("计算指标", metric, "的 24h(统一) 结果为空或无效。"), call.=FALSE) }
        }
        values$metric_results$`24h` <- temp_results_24h # Store under '24h' key
        incProgress(0.2, detail = "24h(统一) 指标计算完成")
        
        
        # 2. Daytime Calculation
        incProgress(0.1, detail = "计算指标 (白天)...")
        temp_results_day <- list()
        for (metric in metrics_to_calculate) {
          limits <- get_limits_from_stored(metric, "day")
          optional_without_limits <- tolower(metric) %in% c("pp", "map") &&
            is.na(limits$lower) && is.na(limits$upper)
          if (tolower(metric) %in% c("sbp", "dbp", "hr") && (is.na(limits$lower) || is.na(limits$upper))) {
            warning(paste("跳过白天计算必需指标", metric, "(上下限未完全设置)"), call.=FALSE); next
          }
          
          if (!is.null(values$individual_series[[metric]]) && length(values$individual_series[[metric]]) > 0) {
            metric_result_df <- if (optional_without_limits) {
              calculate_abpm_metrics_without_limits_individual(
                values$individual_series[[metric]], "day",
                isolate(input$day1_start_h), isolate(input$day1_start_m),
                isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
                isolate(input$day2_start_h), isolate(input$day2_start_m),
                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
              )
            } else {
              calculate_abpm_metrics_for_period_individual(
                values$individual_series[[metric]], "day", limits$upper, limits$lower,
                isolate(input$day1_start_h), isolate(input$day1_start_m),
                isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
                isolate(input$day2_start_h), isolate(input$day2_start_m),
                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
              )
            }
            if (!is.null(metric_result_df) && nrow(metric_result_df) > 0 && ncol(metric_result_df) > 1) {
              cols_to_rename <- setdiff(colnames(metric_result_df), "MASKID")
              colnames(metric_result_df)[colnames(metric_result_df) %in% cols_to_rename] <- paste0(metric, "_", cols_to_rename)
              temp_results_day[[metric]] <- metric_result_df
            } else { warning(paste("计算指标", metric, "的白天结果为空或无效。"), call.=FALSE) }
          } else { warning(paste("指标", metric, "没有可用的患者个体序列，跳过白天计算。"), call. = FALSE) }
        }
        values$metric_results$day <- temp_results_day
        incProgress(0.2, detail = "白天指标计算完成")
        
        
        # 3. Nighttime Calculation
        incProgress(0.1, detail = "计算指标 (夜晚)...")
        temp_results_night <- list()
        for (metric in metrics_to_calculate) {
          limits <- get_limits_from_stored(metric, "night")
          optional_without_limits <- tolower(metric) %in% c("pp", "map") &&
            is.na(limits$lower) && is.na(limits$upper)
          if (tolower(metric) %in% c("sbp", "dbp", "hr") && (is.na(limits$lower) || is.na(limits$upper))) {
            warning(paste("跳过夜晚计算必需指标", metric, "(上下限未完全设置)"), call.=FALSE); next
          }
          
          
          if (!is.null(values$individual_series[[metric]]) && length(values$individual_series[[metric]]) > 0) {
            metric_result_df <- if (optional_without_limits) {
              calculate_abpm_metrics_without_limits_individual(
                values$individual_series[[metric]], "night",
                isolate(input$day1_start_h), isolate(input$day1_start_m),
                isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
                isolate(input$day2_start_h), isolate(input$day2_start_m),
                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
              )
            } else {
              calculate_abpm_metrics_for_period_individual(
                values$individual_series[[metric]], "night", limits$upper, limits$lower,
                isolate(input$day1_start_h), isolate(input$day1_start_m),
                isolate(input$day1_night_start_h), isolate(input$day1_night_start_m),
                isolate(input$day2_start_h), isolate(input$day2_start_m),
                isolate(input$day2_night_start_h), isolate(input$day2_night_start_m)
              )
            }
            if (!is.null(metric_result_df) && nrow(metric_result_df) > 0 && ncol(metric_result_df) > 1) {
              cols_to_rename <- setdiff(colnames(metric_result_df), "MASKID")
              colnames(metric_result_df)[colnames(metric_result_df) %in% cols_to_rename] <- paste0(metric, "_", cols_to_rename)
              temp_results_night[[metric]] <- metric_result_df
            } else { warning(paste("计算指标", metric, "的夜晚结果为空或无效。"), call.=FALSE) }
          } else { warning(paste("指标", metric, "没有可用的患者个体序列，跳过夜晚计算。"), call. = FALSE) }
        }
        values$metric_results$night <- temp_results_night
        incProgress(0.2, detail = "夜晚指标计算完成")
        
        
        # 4. 24-Hour Calculation (Segmented Limits) - NEW
        incProgress(0.1, detail = "计算指标（24h日夜分段阈值）...")
        temp_results_24h_segmented <- calculate_abpm_metrics_24h_segmented_individual(
          individual_series = values$individual_series,
          targets_day = values$targets_used_day,     # Pass stored day targets
          targets_night = values$targets_used_night, # Pass stored night targets
          day_start1_h = isolate(input$day1_start_h), day_start1_m = isolate(input$day1_start_m),
          night_start1_h = isolate(input$day1_night_start_h), night_start1_m = isolate(input$day1_night_start_m),
          day_start2_h = isolate(input$day2_start_h), day_start2_m = isolate(input$day2_start_m),
          night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m)
        )
        values$metric_results$`24h_segmented` <- temp_results_24h_segmented # Store under new key
        incProgress(0.1, detail = "24h（日夜分段阈值）指标计算完成")
        
        
        # --- End Calculation Block ---
        
        incProgress(0.1, detail = "完成！")
        values$metrics_calculated_successfully <- TRUE
        values$calculation_error <- NULL
        
        # Update patient list for visualization (Still based on 24h unified results existence for simplicity)
        if (length(values$metric_results$`24h`) > 0 && !is.null(values$metric_results$`24h`[[1]]) && "MASKID" %in% colnames(values$metric_results$`24h`[[1]])) {
          values$available_patients_viz <- sort(unique(values$metric_results$`24h`[[1]]$MASKID))
        } else { values$available_patients_viz <- character(0) }
        
        showNotification("指标计算完成！现在可以进行可视化分析。", type = "message", duration = 5)
        updateTabsetPanel(session, "main_tabset", selected = "results_tab")
        
      }, error = function(e) {
        values$calculation_error <- e$message
        values$metrics_calculated_successfully <- FALSE
        showNotification(paste("指标计算失败:", e$message), type = "error", duration = NULL)
        values$metric_results <- list(day = list(), night = list(), `24h` = list(), `24h_segmented` = list()); # Reset all
        values$targets_used_day <- list(); values$targets_used_night <- list(); values$targets_used_24h <- list();
        values$available_patients_viz <- character(0)
      }, finally = {
        # Always re-enable buttons after calculation attempt if processing was successful
        if(values$data_processed_successfully) {
          shinyjs::enable("calculate_metrics_btn")
          shinyjs::enable("save_custom_targets_btn") # Re-enable lock button too
          set_target_controls_locked(isTRUE(values$targets_locked))
        } else {
          shinyjs::disable("calculate_metrics_btn")
          shinyjs::disable("save_custom_targets_btn")
        }
      }) # End tryCatch
    }) # End withProgress
  } # End perform_metric_calculation function
  
  
  # --- Trigger Calculation from the Main Calculation Button ---
  observeEvent(input$calculate_metrics_btn, {
    perform_metric_calculation() # Call the calculation function
  }, ignoreInit = TRUE)
  
  
  # --- UI Rendering for Metric Results (MODIFIED FOR 24H SEGMENTED RESULTS TAB) ---
  
  # Generic function to render target ranges display (Unchanged)
  render_target_range_ui_generic <- function(targets_list_reactive, period_suffix) {
    renderUI({
      targets_list <- targets_list_reactive(); req(length(targets_list) > 0)
      tags_to_render <- list(tags$p(tags$strong(icon("bullseye"), "本次计算使用的目标范围:")))
      metrics <- c("SBP", "DBP", "HR", "PP", "MAP")
      
      for (metric in metrics) {
        lower_name <- paste0(tolower(metric), "_", period_suffix, "_lower")
        upper_name <- paste0(tolower(metric), "_", period_suffix, "_upper")
        
        if (lower_name %in% names(targets_list) && upper_name %in% names(targets_list)) {
          lower_val <- targets_list[[lower_name]]; upper_val <- targets_list[[upper_name]]
          lower_is_num <- is.numeric(lower_val) && !is.na(lower_val)
          upper_is_num <- is.numeric(upper_val) && !is.na(upper_val)
          range_text <- if (!lower_is_num && !upper_is_num) { "未设置"
          } else if (!lower_is_num && upper_is_num) { paste0("≤ ", upper_val)
          } else if (lower_is_num && !upper_is_num) { paste0("≥ ", lower_val)
          } else { paste0(lower_val, " - ", upper_val) }
          tags_to_render[[length(tags_to_render) + 1]] <- tags$p(tags$strong(metric, ":"), tags$code(range_text), style = "margin-left: 10px; margin-top: 2px; margin-bottom: 2px;")
        }
      }
      do.call(tagList, tags_to_render)
    })
  }
  
  # Assign renderers for each specific period target display (Unchanged)
  output$target_ranges_day_display <- render_target_range_ui_generic(reactive(values$targets_used_day), "day")
  output$target_ranges_night_display <- render_target_range_ui_generic(reactive(values$targets_used_night), "night")
  output$target_ranges_24h_unified_display <- render_target_range_ui_generic(reactive(values$targets_used_24h), "24h")
  
  # Combined Day/Night target display for the "24h (Segmented)" tab (Unchanged)
  output$target_ranges_daynight_display_combined <- renderUI({
    targets_d <- values$targets_used_day; targets_n <- values$targets_used_night
    req(length(targets_d) > 0, length(targets_n) > 0)
    tags_list <- list(tags$h5(tags$strong("24h（日夜分段阈值）计算使用的日间和夜间目标范围："))) # Clarified title
    metrics <- c("SBP", "DBP", "HR", "PP", "MAP")
    
    format_range <- function(lower_val, upper_val) {
      lower_is_num <- is.numeric(lower_val) && !is.na(lower_val)
      upper_is_num <- is.numeric(upper_val) && !is.na(upper_val)
      if (!lower_is_num && !upper_is_num) { "未设置"
      } else if (!lower_is_num && upper_is_num) { paste0("≤ ", upper_val)
      } else if (lower_is_num && !upper_is_num) { paste0("≥ ", lower_val)
      } else { paste0(lower_val, " - ", upper_val) }
    }
    
    for (metric in metrics) {
      lower_d_name <- paste0(tolower(metric), "_day_lower"); upper_d_name <- paste0(tolower(metric), "_day_upper")
      lower_n_name <- paste0(tolower(metric), "_night_lower"); upper_n_name <- paste0(tolower(metric), "_night_upper")
      
      if (lower_d_name %in% names(targets_d) && upper_d_name %in% names(targets_d) &&
          lower_n_name %in% names(targets_n) && upper_n_name %in% names(targets_n)) {
        
        range_d_text <- format_range(targets_d[[lower_d_name]], targets_d[[upper_d_name]])
        range_n_text <- format_range(targets_n[[lower_n_name]], targets_n[[upper_n_name]])
        
        tags_list[[length(tags_list) + 1]] <- tags$p(
          tags$strong(metric, ":"),
          span(" 白天:", style="color: #555;"), tags$code(range_d_text), "; ",
          span(" 夜晚:", style="color: #555;"), tags$code(range_n_text),
          style = "margin-left: 10px; margin-top: 2px; margin-bottom: 2px;"
        )
      }
    }
    do.call(tagList, tags_list)
  })
  
  
  # Generic function to render the metric tabs UI for results (Updated for segmented key)
  render_results_metric_tabs_ui <- function(period_key) { # Takes the key used in values$metric_results
    renderUI({
      req(values$metrics_calculated_successfully)
      metrics_available <- names(values$metric_results[[period_key]])
      # Use a user-friendly title based on the key
      period_title <- switch(period_key,
                             "day" = "日间（使用日间阈值）",
                             "night" = "夜间（使用夜间阈值）",
                             "24h" = "24h（日夜统一阈值）",
                             "24h_segmented" = "24h（日夜分段阈值）",
                             period_key) # Fallback
      
      if (length(metrics_available) == 0) {
        return(p(paste("没有计算出", period_title, "时段的有效指标结果 (可能是目标范围未设置或计算出错?)。")))
      }
      metric_tabs <- lapply(metrics_available, function(metric) {
        # Use a consistent prefix and suffix based on the period key being rendered
        output_id <- paste0("results_", period_key, "_", tolower(metric), "_table")
        tabPanel(title = metric, DTOutput(output_id))
      })
      do.call(tabsetPanel, c(metric_tabs, id = paste0("results_metric_subtabs_", period_key)))
    })
  }
  
  # Assign renderers for each period's metric tabs UI
  output$day_metric_tabs <- render_results_metric_tabs_ui("day")
  output$night_metric_tabs <- render_results_metric_tabs_ui("night")
  output$`24h_unified_metric_tabs` <- render_results_metric_tabs_ui("24h") # Use '24h' key for unified results
  output$`segmented_24h_metric_tabs` <- render_results_metric_tabs_ui("24h_segmented") # Use '24h_segmented' key
  
  # Generic function to render the DT table (Unchanged)
  render_dt_table <- function(data_reactive,caption = NULL) {
    renderDT({
      data_df <- data_reactive()
      if (is.null(data_df) || !is.data.frame(data_df) || nrow(data_df) == 0) {
        display_msg <- if (!is.null(values$calculation_error) && nzchar(values$calculation_error)) paste("指标计算失败:", values$calculation_error) else if (!is.null(values$processing_error) && nzchar(values$processing_error)) paste("数据处理失败:", values$processing_error) else if (is.null(values$raw_data_input)) "没有可显示的数据。请上传文件或使用内置数据。" else if (!values$data_processed_successfully && input$process_data_btn == 0) "请点击 '处理数据' 按钮。" else if (!values$data_processed_successfully) "数据处理步骤未成功完成或未运行。" else if (!values$metrics_calculated_successfully && input$calculate_metrics_btn == 0) "请点击 '计算指标' 按钮生成结果。" else if (!values$metrics_calculated_successfully) "指标计算步骤未成功完成或未运行。" else "此步骤无数据显示或结果为空 (检查目标范围是否已设置)。"
        return(datatable(data.frame(消息 = display_msg), options = list(dom = 't', searching = FALSE, ordering=FALSE), rownames = FALSE))
      }
      cols_to_round <- names(data_df)[sapply(data_df, is.numeric)]; cols_to_round <- setdiff(cols_to_round, "MASKID")
      if(length(cols_to_round) > 0) { tryCatch({ data_df <- data_df %>% mutate(across(where(is.numeric) & !matches("^MASKID$"), ~ round(.x, 2))) }, error = function(e) { warning(paste("Error during rounding columns:", e$message), call.=FALSE) }) }
      filename_default <- "abpm_results"
      if (!is.null(caption)) { filename_default <-gsub("[^A-Za-z0-9_]", "_", caption); filename_default <- gsub("_+", "_", filename_default); filename_default <- sub("^_|_$", "", filename_default); if (nchar(filename_default) == 0) filename_default <- "abpm_data_export" }
      datatable(data_df, caption = caption, extensions = c('Buttons', 'FixedColumns'), options = list(dom = 'Blfrtip', buttons = list(list(extend = 'copy', text = '<i class="fa fa-copy"></i> 复制'), list(extend = 'csv', text = '<i class="fa fa-file-csv"></i> 导出 CSV', filename = filename_default, titleAttr = '导出为CSV文件', bom = TRUE), list(extend = 'excel', text = '<i class="fa fa-file-excel"></i> 导出 Excel', filename = filename_default, titleAttr = '导出为Excel文件')), scrollX = TRUE, pageLength = 10, searchDelay = 500, search = list(regex = TRUE, caseInsensitive = TRUE), lengthMenu = list(c(10, 25, 50, 100, -1), c('10', '25', '50', '100', '全部')), columnDefs = list(list(className = 'dt-center', targets = '_all')), fixedColumns = list(leftColumns = 1), language = list(url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese.json"), processing = TRUE), filter = 'top', rownames = FALSE, class = 'cell-border stripe compact hover nowrap', escape = FALSE)
    })
  }
  
  # Observe and render DT tables for each metric within each period tab (Updated for segmented key)
  observe({
    req(values$metrics_calculated_successfully, values$metric_results)
    # Use the actual keys: 'day', 'night', '24h', '24h_segmented'
    for (period_key in c("day", "night", "24h", "24h_segmented")) {
      if (!is.null(values$metric_results[[period_key]]) && length(values$metric_results[[period_key]]) > 0) {
        for (metric in names(values$metric_results[[period_key]])) {
          if (!is.null(values$metric_results[[period_key]][[metric]])) {
            local({
              current_period_key <- period_key; current_metric <- metric
              # Construct output ID based on period key
              output_id <- paste0("results_", current_period_key, "_", tolower(current_metric), "_table")
              data_reactive <- reactive({
                req(values$metrics_calculated_successfully,
                    !is.null(values$metric_results),
                    !is.null(values$metric_results[[current_period_key]]),
                    !is.null(values$metric_results[[current_period_key]][[current_metric]]))
                return(values$metric_results[[current_period_key]][[current_metric]])
              })
              period_title <- switch(current_period_key,
                                     "day" = "日间（使用日间阈值）",
                                     "night" = "夜间（使用夜间阈值）",
                                     "24h" = "24h（日夜统一阈值）",
                                     "24h_segmented" = "24h（日夜分段阈值）",
                                     current_period_key)
              output[[output_id]] <- render_dt_table(data_reactive, caption = paste0(period_title, " 指标 - ", current_metric))
            })
          }
        }
      }
    }
  })

  # --- Full-population exports (independent of DT pagination/filtering) ---
  full_export_reactive <- reactive({
    req(values$metrics_calculated_successfully)
    metrics_wide <- build_full_results_wide(values$metric_results)
    assessments <- build_all_personalized_assessments(values$metric_results)
    if (nrow(assessments) > 0) metrics_wide <- left_join(metrics_wide, assessments, by = "MASKID")
    metrics_wide
  })

  output$download_all_csv <- downloadHandler(
    filename = function() paste0("ABPM_四套结果_全部患者_", Sys.Date(), ".csv"),
    content = function(file) {
      export_data <- full_export_reactive()
      connection <- base::file(file, open = "wb")
      on.exit(close(connection), add = TRUE)
      writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), connection)
      write.table(export_data, connection, sep = ",", row.names = FALSE,
                  col.names = TRUE, qmethod = "double", na = "")
    }
  )

  output$download_all_xlsx <- downloadHandler(
    filename = function() paste0("ABPM_四套结果_全部患者_", Sys.Date(), ".xlsx"),
    content = function(file) {
      req(values$metrics_calculated_successfully)
      sheets <- list(`全量宽表` = full_export_reactive())
      assessments <- build_all_personalized_assessments(values$metric_results)
      if (nrow(assessments) > 0) sheets[["个性化分析"]] <- assessments
      period_labels <- c(day = "日间", night = "夜间", `24h` = "24h统一阈值", `24h_segmented` = "24h分段阈值")
      for (period_key in names(period_labels)) {
        for (metric in names(values$metric_results[[period_key]])) {
          sheet_name <- substr(paste0(period_labels[[period_key]], "_", metric), 1, 31)
          sheets[[sheet_name]] <- values$metric_results[[period_key]][[metric]]
        }
      }
      openxlsx::write.xlsx(sheets, file = file, overwrite = TRUE, asTable = TRUE)
    }
  )

  # --- Personalized analysis page ---
  observe({
    req(values$metrics_calculated_successfully)
    patient_ids <- collect_result_patients(values$metric_results)
    current <- isolate(input$analysis_maskid)
    selected <- if (!is.null(current) && current %in% patient_ids) current else if (length(patient_ids) > 0) patient_ids[1] else character(0)
    updateSelectInput(session, "analysis_maskid", choices = patient_ids, selected = selected)
  })

  personal_assessment_reactive <- reactive({
    req(values$metrics_calculated_successfully, input$analysis_maskid)
    build_personalized_assessment(values$metric_results, input$analysis_maskid)
  })

  output$personal_followup_level <- renderUI({
    assessment <- personal_assessment_reactive()
    colour <- switch(assessment$followup,
                     "请尽快就医" = "#c62828",
                     "可择期就医" = "#ef6c00",
                     "定期随访" = "#2e7d32",
                     "#333333")
    tagList(
      h3(style = paste0("color:", colour, ";margin-top:5px;"), icon("stethoscope"), assessment$followup),
      p("分级由平均血压、SD/ARV、TTR、Burden和重度血压信号共同生成。")
    )
  })

  output$personal_dimension_table <- renderDT({
    assessment <- personal_assessment_reactive()
    datatable(assessment$dimensions, rownames = FALSE, escape = FALSE,
              options = list(dom = "t", paging = FALSE, searching = FALSE,
                             ordering = FALSE, scrollX = TRUE))
  })

  output$personal_guideline_table <- renderDT({
    assessment <- personal_assessment_reactive()
    datatable(assessment$guidelines, rownames = FALSE,
              options = list(dom = "t", paging = FALSE, searching = FALSE,
                             ordering = FALSE, scrollX = TRUE))
  })

  output$personal_advice <- renderUI({
    assessment <- personal_assessment_reactive()
    wellPanel(
      tags$ul(lapply(assessment$suggestions, tags$li)),
      p(style = "font-size:0.85em;color:#666;margin-bottom:0;",
        "建议必须结合症状、年龄、妊娠状态、合并症、用药及靶器官损害由临床医生确认。")
    )
  })
  
  
  # --- Visualization Logic ---
  
  # Update patient selector choices when results are ready (Unchanged)
  observe({
    req(values$metrics_calculated_successfully)
    patient_ids <- values$available_patients_viz
    if (length(patient_ids) > 0) {
      current_selection <- isolate(input$viz_maskid)
      selected_val <- if (!is.null(current_selection) && current_selection %in% patient_ids) current_selection else patient_ids[1]
      updateSelectInput(session, "viz_maskid", choices = patient_ids, selected = selected_val)
    } else {
      updateSelectInput(session, "viz_maskid", choices = character(0), selected = character(0))
    }
  })
  
  # Update selected metric from UI (Unchanged)
  observeEvent(input$viz_metric_select, {
    values$selected_metric_viz <- input$viz_metric_select
  }, ignoreNULL = TRUE)
  
  # Reactive to fetch ALL data needed for the currently selected patient/metric across all periods (Updated for segmented key)
  viz_data_reactive <- reactive({
    req(values$metrics_calculated_successfully,
        input$viz_maskid, values$selected_metric_viz,
        values$metric_results,
        length(values$metric_results$`24h_segmented`) > 0, # Ensure segmented results are available
        values$interpolated_dfs,
        values$targets_used_day, values$targets_used_night, values$targets_used_24h,
        values$sorted_times, values$sorted_minutes)
    
    patient_id <- input$viz_maskid
    metric_id <- values$selected_metric_viz
    
    get_period_results <- function(period_key) {
      results_list <- values$metric_results[[period_key]] # Use the key directly
      if (!is.null(results_list) && metric_id %in% names(results_list)) {
        df <- results_list[[metric_id]];
        if (!is.null(df) && "MASKID" %in% names(df)) {
          filtered_df <- df %>% filter(MASKID == patient_id);
          if (nrow(filtered_df) == 1) return(filtered_df)
        }
      }
      # Create a fallback dataframe with the correct patient ID and NA columns if results are missing
      fallback_df <- data.frame(MASKID = patient_id, stringsAsFactors = FALSE)
      expected_cols <- c("max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
                         "Sa", "Sc", "Sd", "AUC", "Ts1_total", "Ts2_total", "Ts3_total",
                         "Load", "cumulative_Load", "TTR", "TOTR", "TUTR",
                         "hyper_Burden", "hypo_Burden", "Se", "Sf")
      placeholder_cols <- paste0(metric_id, "_", expected_cols)
      for(col in placeholder_cols) fallback_df[[col]] <- NA_real_ # Use NA_real_ for numeric types
      return(fallback_df)
    }
    
    # Fetch day, night, unified 24h, and segmented 24h results
    results_24h_unified <- get_period_results("24h")
    results_24h_segmented <- get_period_results("24h_segmented")
    results_day <- get_period_results("day")
    results_night <- get_period_results("night")
    interpolated_data_metric <- values$interpolated_dfs[[metric_id]]
    req(interpolated_data_metric) # Need the interpolated data
    
    list(
      patient_id = patient_id, metric_id = metric_id,
      results_24h = results_24h_unified, # Rename for clarity in downstream code
      results_24h_segmented = results_24h_segmented, # Add segmented results
      results_day = results_day,
      results_night = results_night,
      targets_24h = values$targets_used_24h, # Unified 24h targets
      targets_day = values$targets_used_day,
      targets_night = values$targets_used_night,
      interpolated_data = interpolated_data_metric,
      sorted_times = values$sorted_times, sorted_minutes = values$sorted_minutes
    )
  })
  
  # --- Render Viz Summary Header (Based on Unified 24h Results) (Unchanged) ---
  output$viz_summary_header <- renderUI({
    data <- viz_data_reactive(); req(data)
    results_24h_unified <- data$results_24h # Uses the unified 24h results
    req(nrow(results_24h_unified)==1)
    
    metric_id <- data$metric_id
    mean_col <- paste0(metric_id, "_mean")
    ttr_col <- paste0(metric_id, "_TTR")
    
    mean_val <- if(mean_col %in% names(results_24h_unified)) results_24h_unified[[mean_col]] else NA
    ttr_val <- if(ttr_col %in% names(results_24h_unified)) results_24h_unified[[ttr_col]] else NA
    
    format_num <- function(value, decimals = 1) { if(is.null(value) || is.na(value) || !is.finite(value)) return("N/A"); format(round(value, decimals), nsmall = decimals) }
    format_perc <- function(value, decimals = 1) { if(is.null(value) || is.na(value) || !is.finite(value)) return("N/A"); paste0(round(value, decimals), "%") }
    
    tagList(
      p(style="margin-bottom: 5px;",
        tags$strong("患者:"), tags$code(data$patient_id), " | ",
        tags$strong("指标:"), tags$code(data$metric_id)
      ),
      p(style="margin-bottom: 0px;",
        tags$strong("24h(统一) 均值: "), format_num(mean_val), " | ", # Clarified source
        tags$strong("24h(统一) TTR: "), format_perc(ttr_val)   # Clarified source
      )
    )
  })
  
  
  # --- Helper Functions for Rendering Viz UI Components (Updated for segmented key) ---
  render_viz_info_ui <- function(period_key) { # Now uses the period key directly
    renderUI({
      data <- viz_data_reactive(); req(data)
      # Select correct result data based on key
      selected_data <- data[[paste0("results_", period_key)]]
      req(nrow(selected_data) == 1)
      
      metric_id <- data$metric_id
      format_perc <- function(value, decimals = 1) { if(is.null(value) || is.na(value) || !is.finite(value)) return("N/A"); paste0(round(value, decimals), "%") }
      format_num <- function(value, decimals = 2) { if(is.null(value) || is.na(value) || !is.finite(value)) return("N/A"); format(round(value, decimals), nsmall = decimals) }
      
      ttr_col <- paste0(metric_id, "_TTR"); totr_col <- paste0(metric_id, "_TOTR"); tutr_col <- paste0(metric_id, "_TUTR")
      hyper_col <- paste0(metric_id, "_hyper_Burden"); hypo_col <- paste0(metric_id, "_hypo_Burden")
      sd_col <- paste0(metric_id, "_SD"); arv_col <- paste0(metric_id, "_ARV")
      
      ttr_val <- if(ttr_col %in% names(selected_data)) selected_data[[ttr_col]][1] else NA
      totr_val <- if(totr_col %in% names(selected_data)) selected_data[[totr_col]][1] else NA
      tutr_val <- if(tutr_col %in% names(selected_data)) selected_data[[tutr_col]][1] else NA
      hyper_val <- if(hyper_col %in% names(selected_data)) selected_data[[hyper_col]][1] else NA
      hypo_val <- if(hypo_col %in% names(selected_data)) selected_data[[hypo_col]][1] else NA
      sd_val <- if(sd_col %in% names(selected_data)) selected_data[[sd_col]][1] else NA
      arv_val <- if(arv_col %in% names(selected_data)) selected_data[[arv_col]][1] else NA
      
      sd_str <- format_num(sd_val); arv_str <- format_num(arv_val)
      
      tagList( fluidRow(
        column(6, tags$ul(style = "list-style-type: none; padding-left: 5px; font-size: 0.95em; margin-bottom: 0;",
                          tags$li(tags$span(style = "color: #4CAF50;", icon("check-circle"), " TTR: "), tags$strong(format_perc(ttr_val))),
                          tags$li(tags$span(style = "color: #F44336;", icon("arrow-up"), " TOTR: "), tags$strong(format_perc(totr_val))),
                          tags$li(tags$span(style = "color: #1565C0;", icon("arrow-down"), " TUTR: "), tags$strong(format_perc(tutr_val)))
        )),
        column(6, tags$ul(style = "list-style-type: none; padding-left: 5px; font-size: 0.95em; margin-bottom: 0;",
                          tags$li(tags$span(style = "color: #D32F2F;", icon("tachometer-alt"), " 升高负担: "), tags$strong(format_perc(hyper_val))),
                          tags$li(tags$span(style = "color: #1A237E;", icon("tachometer-alt"), " 偏低负担: "), tags$strong(format_perc(hypo_val))),
                          tags$li(tags$span(style = "color: #FF9800;", icon("wave-square"), " SD: "), tags$strong(sd_str)),
                          tags$li(tags$span(style = "color: #795548;", icon("ruler-combined"), " ARV: "), tags$strong(arv_str))
        ))
      ))
    })
  }
  render_patient_summary_print <- function(period_key) { # Now uses the period key
    renderPrint({
      data <- viz_data_reactive(); req(data)
      # Select correct result data based on key
      selected_data <- data[[paste0("results_", period_key)]]
      req(nrow(selected_data) == 1)
      
      metric_id <- data$metric_id
      format_val_print <- function(value, digits = 2, suffix = "") { if (is.null(value) || is.na(value) || !is.finite(value)) return("N/A"); paste0(format(round(value, digits), nsmall = digits), suffix) }
      
      mean_col <- paste0(metric_id,"_mean"); sd_col <- paste0(metric_id,"_SD"); cv_col <- paste0(metric_id,"_CV"); arv_col <- paste0(metric_id,"_ARV"); vim_col <- paste0(metric_id,"_VIM")
      max_col <- paste0(metric_id,"_max_value"); min_col <- paste0(metric_id,"_min_value"); delta_col <- paste0(metric_id,"_Delta")
      load_col <- paste0(metric_id,"_Load"); cumload_col <- paste0(metric_id,"_cumulative_Load"); auc_col <- paste0(metric_id,"_AUC")
      
      mean_val <- if(mean_col %in% names(selected_data)) selected_data[[mean_col]][1] else NA
      sd_val <- if(sd_col %in% names(selected_data)) selected_data[[sd_col]][1] else NA
      cv_val <- if(cv_col %in% names(selected_data)) selected_data[[cv_col]][1] else NA
      arv_val <- if(arv_col %in% names(selected_data)) selected_data[[arv_col]][1] else NA
      vim_val <- if(vim_col %in% names(selected_data)) selected_data[[vim_col]][1] else NA
      max_val <- if(max_col %in% names(selected_data)) selected_data[[max_col]][1] else NA
      min_val <- if(min_col %in% names(selected_data)) selected_data[[min_col]][1] else NA
      delta_val <- if(delta_col %in% names(selected_data)) selected_data[[delta_col]][1] else NA
      load_val <- if(load_col %in% names(selected_data)) selected_data[[load_col]][1] else NA
      cumload_val <- if(cumload_col %in% names(selected_data)) selected_data[[cumload_col]][1] else NA
      auc_val <- if(auc_col %in% names(selected_data)) selected_data[[auc_col]][1] else NA
      
      cat(sprintf("%-22s: %s\n", "平均值 (Mean)", format_val_print(mean_val)))
      cat(sprintf("%-22s: %s\n", "标准差 (SD)", format_val_print(sd_val)))
      cat(sprintf("%-22s: %s\n", "变异系数 (CV %)", format_val_print(cv_val, suffix="%")))
      cat(sprintf("%-22s: %s\n", "平均真实变异 (ARV)", format_val_print(arv_val)))
      cat(sprintf("%-22s: %s\n", "均值独立变异 (VIM)", format_val_print(vim_val)))
      cat(sprintf("%-22s: %s\n", "最大值 (Max)", format_val_print(max_val, 0)))
      cat(sprintf("%-22s: %s\n", "最小值 (Min)", format_val_print(min_val, 0)))
      cat(sprintf("%-22s: %s\n", "波动范围 (Delta)", format_val_print(delta_val, 0)))
      cat(sprintf("%-22s: %s\n", "负荷 (Load %)", format_val_print(load_val, suffix="%")))
      cat(sprintf("%-22s: %s\n", "累积负荷 (Cum. Load %)", format_val_print(cumload_val, suffix="%")))
      cat(sprintf("%-22s: %s\n", "曲线下面积 (AUC)", format_val_print(auc_val)))
    })
  }
  
  # --- Assign Renderers for VIZ TAB - 24h (Unified Limits) ---
  output$viz_info_24h_unified <- render_viz_info_ui("24h") # Use '24h' key for unified results
  output$patient_summary_24h_unified <- render_patient_summary_print("24h") # Use '24h' key for unified results
  output$bp_trend_chart_24h_unified_limit <- renderPlotly({
    data <- viz_data_reactive(); req(data)
    metric_lc <- tolower(data$metric_id)
    limits_24h <- data$targets_24h # Use the unified 24h targets
    lower_lim <- limits_24h[[paste0(metric_lc, "_24h_lower")]]
    upper_lim <- limits_24h[[paste0(metric_lc, "_24h_upper")]]
    p <- create_metric_trend_chart(
      data$interpolated_data, data$sorted_times, data$sorted_minutes,
      data$patient_id, data$metric_id, upper_lim, lower_lim
    )
    p %>% layout(title = NULL)
  })
  output$time_in_range_donut_24h_unified <- renderPlotly({
    data <- viz_data_reactive(); req(data, ncol(data$results_24h) > 1)
    p <- create_time_in_range_donut(data$results_24h, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$burden_chart_24h_unified <- renderPlotly({
    data <- viz_data_reactive(); req(data, ncol(data$results_24h) > 1)
    p <- create_burden_chart(data$results_24h, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$variability_chart_24h_unified <- renderPlotly({
    data <- viz_data_reactive(); req(data, ncol(data$results_24h) > 1)
    ref_vals <- VARIABILITY_REFERENCE_VALUES[[data$metric_id]]
    p <- create_variability_chart(data$results_24h, data$patient_id, data$metric_id,
                                  sd_reference = ref_vals$sd, arv_reference = ref_vals$arv)
    p %>% layout(title = NULL)
  })
  
  # --- Assign Renderers for VIZ TAB - 24h (Segmented Limits/Background) ---
  output$bp_trend_chart_24h_segmented_limits <- renderPlotly({
    data <- viz_data_reactive(); req(data)
    metric_lc <- tolower(data$metric_id)
    targets_day <- data$targets_day; targets_night <- data$targets_night
    day_l <- targets_day[[paste0(metric_lc, "_day_lower")]]; day_u <- targets_day[[paste0(metric_lc, "_day_upper")]]
    night_l <- targets_night[[paste0(metric_lc, "_night_lower")]]; night_u <- targets_night[[paste0(metric_lc, "_night_upper")]]
    p <- create_metric_trend_chart_24h(
      bp_data = data$interpolated_data, sorted_times = data$sorted_times, sorted_minutes = data$sorted_minutes,
      maskid_selected = data$patient_id, metric_name = data$metric_id,
      day_upper_limit = day_u, day_lower_limit = day_l,
      night_upper_limit = night_u, night_lower_limit = night_l,
      day_start1_h = isolate(input$day1_start_h), day_start1_m = isolate(input$day1_start_m),
      night_start1_h = isolate(input$day1_night_start_h), night_start1_m = isolate(input$day1_night_start_m),
      day_start2_h = isolate(input$day2_start_h), day_start2_m = isolate(input$day2_start_m),
      night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m)
    )
    p %>% layout(title = NULL)
  })
  # Day/Night Summaries (use existing renderers with new IDs)
  output$viz_info_day_combined <- render_viz_info_ui("day")
  output$viz_info_night_combined <- render_viz_info_ui("night")
  output$patient_summary_day_combined <- render_patient_summary_print("day")
  output$patient_summary_night_combined <- render_patient_summary_print("night")
  # Segmented 24h Results Summaries and Plots
  output$viz_info_24h_segmented <- render_viz_info_ui("24h_segmented") # Use segmented results key
  output$patient_summary_24h_segmented <- render_patient_summary_print("24h_segmented") # Use segmented results key
  output$time_in_range_donut_24h_segmented <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_24h_segmented), ncol(data$results_24h_segmented) > 1)
    p <- create_time_in_range_donut(data$results_24h_segmented, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$burden_chart_24h_segmented <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_24h_segmented), ncol(data$results_24h_segmented) > 1)
    p <- create_burden_chart(data$results_24h_segmented, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$variability_chart_24h_segmented <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_24h_segmented), ncol(data$results_24h_segmented) > 1)
    ref_vals <- VARIABILITY_REFERENCE_VALUES[[data$metric_id]]
    # Note: SD/ARV for segmented 24h are calculated on the *full* 24h data in calculate_abpm_metrics_24h_segmented
    p <- create_variability_chart(data$results_24h_segmented, data$patient_id, data$metric_id,
                                  sd_reference = ref_vals$sd, arv_reference = ref_vals$arv)
    p %>% layout(title = NULL)
  })
  
  
  # --- Assign Renderers for VIZ TAB - Day ---
  output$viz_info_day <- render_viz_info_ui("day")
  output$patient_summary_day <- render_patient_summary_print("day")
  output$bp_trend_chart_day <- renderPlotly({ # Show the segmented chart here as well
    data <- viz_data_reactive(); req(data)
    metric_lc <- tolower(data$metric_id)
    targets_day <- data$targets_day; targets_night <- data$targets_night
    day_l <- targets_day[[paste0(metric_lc, "_day_lower")]]; day_u <- targets_day[[paste0(metric_lc, "_day_upper")]]
    night_l <- targets_night[[paste0(metric_lc, "_night_lower")]]; night_u <- targets_night[[paste0(metric_lc, "_night_upper")]]
    p <- create_metric_trend_chart_24h(
      bp_data = data$interpolated_data, sorted_times = data$sorted_times, sorted_minutes = data$sorted_minutes,
      maskid_selected = data$patient_id, metric_name = data$metric_id,
      day_upper_limit = day_u, day_lower_limit = day_l,
      night_upper_limit = night_u, night_lower_limit = night_l,
      day_start1_h = isolate(input$day1_start_h), day_start1_m = isolate(input$day1_start_m),
      night_start1_h = isolate(input$day1_night_start_h), night_start1_m = isolate(input$day1_night_start_m),
      day_start2_h = isolate(input$day2_start_h), day_start2_m = isolate(input$day2_start_m),
      night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m)
    )
    p %>% layout(title = NULL)
  })
  output$time_in_range_donut_day <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_day), ncol(data$results_day) > 1)
    p <- create_time_in_range_donut(data$results_day, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$burden_chart_day <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_day), ncol(data$results_day) > 1)
    p <- create_burden_chart(data$results_day, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$variability_chart_day <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_day), ncol(data$results_day) > 1)
    ref_vals <- VARIABILITY_REFERENCE_VALUES[[data$metric_id]]
    p <- create_variability_chart(data$results_day, data$patient_id, data$metric_id,
                                  sd_reference = ref_vals$sd, arv_reference = ref_vals$arv)
    p %>% layout(title = NULL)
  })
  
  # --- Assign Renderers for VIZ TAB - Night ---
  output$viz_info_night <- render_viz_info_ui("night")
  output$patient_summary_night <- render_patient_summary_print("night")
  output$bp_trend_chart_night <- renderPlotly({ # Show the segmented chart here as well
    data <- viz_data_reactive(); req(data)
    metric_lc <- tolower(data$metric_id)
    targets_day <- data$targets_day; targets_night <- data$targets_night
    day_l <- targets_day[[paste0(metric_lc, "_day_lower")]]; day_u <- targets_day[[paste0(metric_lc, "_day_upper")]]
    night_l <- targets_night[[paste0(metric_lc, "_night_lower")]]; night_u <- targets_night[[paste0(metric_lc, "_night_upper")]]
    p <- create_metric_trend_chart_24h(
      bp_data = data$interpolated_data, sorted_times = data$sorted_times, sorted_minutes = data$sorted_minutes,
      maskid_selected = data$patient_id, metric_name = data$metric_id,
      day_upper_limit = day_u, day_lower_limit = day_l,
      night_upper_limit = night_u, night_lower_limit = night_l,
      day_start1_h = isolate(input$day1_start_h), day_start1_m = isolate(input$day1_start_m),
      night_start1_h = isolate(input$day1_night_start_h), night_start1_m = isolate(input$day1_night_start_m),
      day_start2_h = isolate(input$day2_start_h), day_start2_m = isolate(input$day2_start_m),
      night_start2_h = isolate(input$day2_night_start_h), night_start2_m = isolate(input$day2_night_start_m)
    )
    p %>% layout(title = NULL)
  })
  output$time_in_range_donut_night <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_night), ncol(data$results_night) > 1)
    p <- create_time_in_range_donut(data$results_night, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$burden_chart_night <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_night), ncol(data$results_night) > 1)
    p <- create_burden_chart(data$results_night, data$patient_id, data$metric_id)
    p %>% layout(title = NULL)
  })
  output$variability_chart_night <- renderPlotly({
    data <- viz_data_reactive(); req(data, !is.null(data$results_night), ncol(data$results_night) > 1)
    ref_vals <- VARIABILITY_REFERENCE_VALUES[[data$metric_id]]
    p <- create_variability_chart(data$results_night, data$patient_id, data$metric_id,
                                  sd_reference = ref_vals$sd, arv_reference = ref_vals$arv)
    p %>% layout(title = NULL)
  })
  
  
} # End server function

# --- 5. Run the Application ---
shinyApp(ui = ui, server = server)
