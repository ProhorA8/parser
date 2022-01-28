require 'curb'
require 'nokogiri'
require 'csv'

# получение страниц
def formation_links_pages(url_input)
  array_page_urls = []
  # хардкожу пагинацию
  (1..10).each do |i|
    # через тернарный оператор
    # при 1 передаём ссылку без номера страницы, далее собираем ссылку с номером страницы
    i == 1 ? array_page_urls << url_input : array_page_urls << "#{url_input}?p=#{i}"
  end

  array_page_urls
end

# получение ссылок
def get_product_links(array_page_links)
  array_product_links = []

  array_page_links.each do |url|
    doc = get_document(url)

    # находим ссылку для каждого продукта
    doc.xpath("//").each do |product_link|
      print "."

      array_product_links << product_link
    end
  end

  array_product_links
end

# получение документа
def get_document(url)
  c = Curl::Easy.new(url)
  c.ssl_verify_peer = false
  c.perform
  html = c.body_str
  Nokogiri::HTML(html)
end

# имитация загрузки
def show_load
  print '.'
end

# сбор данных
def product_data(doc)
  array_product_string = []
  # получение имени продукта
  doc.xpath("//").each {|data_name| array_product_string << data_name.text.gsub(/\b./, &:upcase).strip + ' – '}
  # получение цены
  doc.xpath("//").each {|data_price| array_product_string << '%.2f' % data_price.text.to_f + ', '}
  # получение ссылки изображения
  doc.xpath("//").each {|data_img_link| array_product_string << data_img_link.value + "\n"}

  show_load
  # превращаем массив в строку
  array_product_string.join('')
end

# сбор данных мультипродукта
def multiproduct_data(doc, tags_quantity)
  array_product_string = []
  for i in 1..tags_quantity
    # получение имени продукта
    doc.xpath("//").each {|data_name| array_product_string << data_name.text.gsub(/\b./, &:upcase).strip + ' – '}
    # получение цены для вариации продукта
    doc.xpath("//").each {|data_price| array_product_string << '%.2f' % data_price.text.to_f + ', '}
    # получение ссылки изображения
    doc.xpath("//").each {|data_img_link| array_product_string << data_img_link.value + "\n"}
  end

  show_load
  # превращаем массив в строку
  array_product_string.join('')
end

# определение типа продукта
def get_type_products(array_product_links)
  data_string = "Name, Price, Image\n"
  array_product_links.each do |url|
    doc = get_document(url)

    # находим количество тегов у продукта
    tags_quantity = doc.xpath("//").count
    # если количество тегов '' у продукта больше одного, то это мультипродукт, если нет – обычный
    data_string = if tags_quantity > 1
      # добавляем полученные мультиданные к начальной строке
      multiproduct_data(doc, tags_quantity)
    else
      # добавляем полученные данные к начальной строке
      product_data(doc)
    end
  end

  data_string
end

# запись данных в файл
def writing_file(file_name, data_string)
  File.write(file_name, data_string)
  CSV.table(file_name)
end

puts 'Передайте ссылку'
url_input = STDIN.gets.chomp

puts 'Введите имя файла:'
file_name_input = STDIN.gets.chomp + '.csv'

puts 'Сбор ссылок товаров'
array_page_links = formation_links_pages(url_input)
array_product_links = get_product_links(array_page_links)
puts "\nСбор данных товаров"
data_string = get_type_products(array_product_links)
writing_file(file_name_input, data_string)
puts "\nИнформация успешно сохранена!"
