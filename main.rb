require 'curb'
require 'nokogiri'
require 'csv'

# получение документа
module Document
  def get_document(url)
    c = Curl::Easy.new url
    c.ssl_verify_peer = false
    c.perform
    html = c.body_str
    Nokogiri::HTML(html)
  end
end

#  имитация загрузки
module SimulationDownload
  def show_load
    print '.'
  end
end

# отвечает за создание ссылок на страницы и ссылок о каждом товаре
class Link
  include Document
  include SimulationDownload

  def initialize
    @url_input = ARGV.first
    check_input
    formation_links_pages
    say_get_links
    get_product_links
  end

  def check_input
    # проверка количества переданных аргументов
    if ARGV.length != 2
      puts 'Нам нужно ровно два аргумента'
      exit
    end
  end

  def say_get_links
    puts 'Сбор ссылок товаров'
  end

  # получение ссылок товаров
  def get_product_links
    array_product_links = formation_links_pages.map do |url|
      doc = get_document url

      # найти ссылку для каждого товара
      doc.xpath("//").map do |product_link|
        show_load
        product_link.value
      end
    end

    # преобразовать многомерный массив в одномерный
    array_product_links.flatten
  end

  private

  # получение страниц
  def formation_links_pages
    doc = get_document @url_input

    # получить количество страниц
    count_pages = doc.xpath("//").text.to_i
    # через тернарным оператор
    # если 1, передаем ссылку без номера страницы, затем собираем ссылку с номером страницы
    (1..count_pages).map { |i| i == 1 ? @url_input : "#{@url_input}....#{i}" }
  end
end

# отвечает за определения типов и за получение данных о товаре
class Product < Link
  def initialize
    @array_product_links = Link.new.get_product_links
    say_get_products
  end

  def say_get_products
    puts "\nСбор данных товаров"
  end

  # определение типа продукта
  def get_type_products
    data_string = @array_product_links.map do |url|
      doc = get_document url

      # найти количество тегов для товара
      tags_quantity = doc.xpath("//").count
      # если количество тегов '' в товаре больше одного, то это мультитовара, если нет, то обычный
      (tags_quantity > 1 ? multiproduct_data(doc, tags_quantity) : product_data(doc))
    end

    data_string.flatten(1)
  end

  private

  # сбор данных обычного товара
  def product_data(doc)
    array_product_string = ''
    # получить название товара
    array_product_string << "#{doc.xpath("//")}; "
    # получить цену
    array_product_string << if doc.xpath("//").count.zero?
                              "#{'%.2f' % doc.xpath("//").text.to_f}; "
                            else
                              "#{'%.2f' % doc.xpath("//").text.to_f}; "
                            end
    # получить изображение
    array_product_string << "#{doc.xpath("//").text}\n"

    show_load
    # массив в строку
    array_product_string.split("\n").map { |x| [] << x}
  end

  # сбор данных мультитовара
  def multiproduct_data(doc, tags_quantity)
    array_product_string = ''

    (1..tags_quantity).each do |i|
      # получение имени
      array_product_string << "#{doc.xpath("//").text}; "
      # получение цены
      array_product_string << if doc.xpath("//").count > 1
                                "#{'%.2f' % doc.xpath("//#{i}").text.to_f}; "
                              else
                                "#{'%.2f' % doc.xpath("//#{i}").text.to_f}; "
                              end
      # получение изображения
      array_product_string << "#{doc.xpath("//").text}\n"
    end

    show_load
    # массив в строку
    array_product_string.split("\n").map { |x| [] << x }
  end
end

# отвечает за сохранение данных в документе
class List
  def initialize
    array_arrays_products = Product.new.get_type_products
    writing_file array_arrays_products
  end

  # записать данные в файл
  def writing_file(arrays_products)
    headers = ['Name; Price; Image']

    CSV.open("#{ARGV.last}.csv", 'ab', write_headers: true, headers: headers) do |csv|
      arrays_products.each do |array_product|
        csv << array_product
      end
    end
  end
end

List.new
puts "\nИнформация успешно сохранена!"
