# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html
import scrapy
from scrapy.pipelines.images import ImagesPipeline
import os
from Douyu.settings import IMAGES_STORE as image_path

class DouyuPipeline(ImagesPipeline):
	def get_media_requests(self, item, info):
		image = item['image']
		yield scrapy.Request(image)
	def item_completed(self, results, item, info):
		path = [x['path'] for ok, x in results if ok]
		os.rename(image_path + path[0], image_path + item['nickname'] + '.jpg')
		return item


