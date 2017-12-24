import scrapy
from tutorial.items import TutorialItem


class DmozSpider(scrapy.Spider):
    name = "dmoz"
    allowed_domains = ["www.itcast.cn"]
    start_urls = [
        "http://www.itcast.cn/channel/teacher.shtml"
    ]

    def parse(self, response):
        node_list = response.xpath("//div[@class='li_txt']")
        for node in node_list:
            name = node.xpath("./h3/text()").extract()
            title = node.xpath("./h4/text()").extract()
            info = node.xpath("./p/text()").extract()

            item = TutorialItem()

            item['name'] = name[0]
            item['title'] = title[0]
            item['info'] = info[0]
            
            yield item