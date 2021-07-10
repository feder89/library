import { Component, OnInit, OnChanges, SimpleChanges, Input } from '@angular/core';
import { Book } from 'src/app/interfaces/book';
import { BookService } from 'src/app/services/book.service';
import { PublisherService } from 'src/app/services/publisher.service';
import { Publisher } from 'src/app/interfaces/publisher';
import { MessageService } from 'primeng/components/common/messageservice';
import { AppComponent } from 'src/app/app.component';
import { BookComponent } from '../book.component';
import { Utils } from 'src/app/util/utils';

@Component({
  selector: 'app-book-detail',
  templateUrl: './book-detail.component.html',
  styleUrls: ['./book-detail.component.css']
})
export class BookDetailComponent implements OnInit, OnChanges {
  constructor(private bookService: BookService,
    private publisherService: PublisherService,
    private app: AppComponent,
    private bookComponent: BookComponent) { }

  private static mapper: Utils = new Utils();
  @Input() bookId: number;
  book: Book;
  publishers: Publisher[] = [];
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['bookId'] && changes['bookId'].currentValue != null && changes['bookId'].currentValue !== -1) {
      this.loadBookInfo(changes['bookId'].currentValue);
    } else if (changes['bookId'] && changes['bookId'].currentValue === -1) {
      this.initBook();
    } else {
      this.initBook();
    }
  }

  ngOnInit() {

    this.loadPublishers();
  }

  initBook(): void {
    this.book = {
      casa_editrice: 0,
      case_editrici: null,
      id: null,
      codice_isbn: '',
      prezzo: 0,
      titolo: '',
      tomi: 1,
      materia: ''
    };
  }

  loadBookInfo(idBook: number): void {
    this.bookService.getBooks(idBook).subscribe(res => {
      this.book = res[0];
    });
  }

  loadPublishers(): void {
    this.publisherService.getPublishers().subscribe(res => {
      this.publishers = res;
    });
  }

  save(): void {
    if (this.bookId === null || this.bookId === -1) {
      this.insertBook();
    } else {
      this.updateBook();
    }
  }

  updateBook(): void {
    this.bookService.updateBook(BookDetailComponent.mapper.mapperBookToDbObject(this.book))
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Libro modificato');
          this.bookComponent.displayDetailDialog = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  insertBook(): void {
    this.bookService.insertBook(BookDetailComponent.mapper.mapperBookToDbObject(this.book)).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Libro creato');
        this.bookComponent.displayDetailDialog = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

  public onChangeCasaEditriveSelect(evt): void {
    this.book.casa_editrice = evt.value.id;
  }

}
