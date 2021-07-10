import { Component, Input, OnChanges, SimpleChanges, Output, EventEmitter } from '@angular/core';
import { AppComponent } from 'src/app/app.component';
import { BookingComponent } from 'src/app/components/booking/booking.component';
import { Student } from 'src/app/interfaces/student';
import { BookingService } from 'src/app/services/booking.service';
import { StudentService } from 'src/app/services/student.service';
import { Utils } from 'src/app/util/utils';
import { SelectItem } from 'primeng/components/common/selectitem';
import { BookService } from 'src/app/services/book.service';
import { ClassesService } from 'src/app/services/classes.service';
import { Status } from 'src/app/interfaces/status.enum';
import * as _ from 'lodash';
import { runInThisContext } from 'vm';


@Component({
  selector: 'app-booking-detail',
  templateUrl: './booking-detail.component.html',
  styleUrls: ['./booking-detail.component.css']
})
export class BookingDetailComponent implements OnChanges {
  private alreadyBooked: any[] = [];
  public toBeBooked: any[] = [];
  public booksToBeBooked: any[];
  @Output() open: EventEmitter<any> = new EventEmitter();
  public bookingId: number;
  public studentId: number;
  public students: SelectItem[];
  public mapper: Utils = new Utils();
  public bookingInfo: any;
  @Input() classId: number;
  @Input() bookingQuery: any;
  public selectedStudent: any;
  public displayBookList: boolean;
  public allClassBooks: any[];
  public cedola: boolean;

  constructor(private bookingService: BookingService,
    private app: AppComponent,
    private bookingComponent: BookingComponent,
    private studentService: StudentService,
    private bookService: BookService) {
    this.bookingInfo = {
      data: null,
      caparra: 0
    };
  }
  ngOnChanges(changes: SimpleChanges): void {
    if (changes['bookingQuery'] && changes['bookingQuery'].currentValue != null) {
      this.bookingId = changes['bookingQuery'].currentValue['bookingId'];
      this.bookingInfo.id = changes['bookingQuery'].currentValue['bookingId'];
      this.studentId = changes['bookingQuery'].currentValue['studentId'];
      this.loadData();
    } else {
      this.bookingId = null;
      this.bookingInfo.id = null;
      this.studentId = null;
      this.bookingInfo.caparra = 0;
      this.bookingInfo.data = null;
      this.bookingInfo.note = '';
    }
    if (changes['classId'] && changes['classId'].currentValue != null) {
      this.selectedStudent = { student: this.studentId, class: this.classId };
    } else {
      this.selectedStudent = {};
    }
    this.loadStudentList();
    this.bookingInfo.data = this.bookingInfo.data ? this.bookingInfo.data : new Date();
  }

  private loadBookingInfo(student: number, booking: number): void {
    this.bookingService.getBookingDetail(booking, student)
      .subscribe(
        res => {
          if (res.length > 0) {
            this.toBeBooked = res;
            this.alreadyBooked = res;
            this.bookingInfo = res[0].prenotazioni;
            this.classId = res[0].studenti.classe;
            this.selectedStudent = { student: res[0].studente, class: res[0].studenti.classe };
            this.loadBooksByStudent(res[0].studente, res[0].studenti, res[0].prenotazioni, res);
            this.cedola = res[0].cedola;
          }
        }
      );
  }

  public onCheck(evt) {
    this.toBeBooked.forEach(b => {
      b.cedola = evt;
    });
  }

  private loadBooksByStudent(stud: number, studentiObj: any, prenotazioniObj: any, bookings): void {
    this.bookingService.getAllBooksForStudent(stud)
      .subscribe(
        res => {
          this.allClassBooks = [];
          res.forEach(el => {
            this.bookService.getBooks(el.libro)
              .subscribe(
                res_ => {
                  el.studenti = studentiObj;
                  el.prenotazioni = prenotazioniObj;
                  el.libri = res_[0];
                  el.stato = Status.NON_ORDINATO;
                  bookings.forEach(b => {
                    if (b.libri.id === el.libro) {
                      el.stato = b.stato;
                    }
                  });
                  this.allClassBooks.push(el);
                }
              );

          });

        }
      );
  }

  public checkToBeBookeNotEmpty() {
    return this.toBeBooked.length > 0;
  }


  private loadData(): void {
    if (this.studentId != null && this.bookingId != null) {
      this.loadBookingInfo(this.studentId, this.bookingId);
    }
  }

  private loadStudentList(): void {
    this.studentService.getStudents()
      .subscribe(
        res => {
          this.students = [];
          res.forEach(el => {
            this.students.push({
              value: { student: el.id, class: el.classe },
              label: el.cognome + ' ' + el.nome
            });
          });
        }
      );
  }

  public openBookList(): void {
    this.open.emit('bookList');
    this.displayBookList = true;
  }

  public createStudent(): void {
    this.open.emit('student');
  }


  public onSelectStudent(evt): void {
    this.studentId = evt.value.student;
    this.classId = evt.value.class;
    this.loadData();
  }

  public onChangeFoderatura(evt, obj) {
    const idx = this.toBeBooked.map(t => t.libri.id).indexOf(obj.libri.id);
    this.toBeBooked[idx].foderatura = evt;
  }

  public save(): void {
    this.saveBookingInfo();
    let object: any[] = [];
    const toBeCreated = _.differenceBy(this.toBeBooked, this.alreadyBooked, 'id');
    const toBeUpdated = _.difference(this.toBeBooked, toBeCreated);

    if (toBeUpdated.length > 0) {
      toBeUpdated.forEach(el => {
        object.push(this.mapper.mapperBookingToDbObject(el, this.bookingInfo.id, this.studentId));
      });
    }
    if (toBeCreated.length > 0) {
      object = [];
      toBeCreated.forEach(el => {
        object.push(this.mapper.mapperBookingToDbObject(el, this.bookingInfo.id, this.studentId));
      });
    }


    this.bookingService.insertOrUpdateBookings(object)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Prenotazione Salvata');
          this.bookingComponent.displayDetailDialog = false;
          this.bookingInfo.data = null;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  public saveBookingInfo(): void {
    const load: boolean = this.bookingInfo.id == null;
    this.bookingService.insertBooking(this.mapper.mappingBookingToDbObject(this.bookingInfo))
      .subscribe(
        res => {
          this.bookingInfo = res[0];
          this.bookingId = res[0].id;
          this.app.handleToastMessages('success', 'Completato', 'Info Prenotazione Salvate');
          if (load) {
            this.loadBooks();
          }
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  public cloaseBookList(): void {
    this.toBeBooked = [];
    this.booksToBeBooked.forEach(el => {
      this.toBeBooked.push({
        libri: { id: el.id, titolo: el.titolo, case_editrici: el.nome },
        stato: 'In prenotazione',
        foderatura: false,
        cedola: false
      });
    });
  }

  private loadBooks(): void {
    this.bookingService.getAllBooksForStudent(this.studentId)
      .subscribe(
        res => {
          this.toBeBooked = [];
          this.allClassBooks = [];
          res.forEach(el => {
            this.bookService.getBooks(el.libro)
              .subscribe(
                res_ => {
                  el.libri = res_[0];
                  el.stato = Status.NON_ORDINATO;
                  this.allClassBooks.push(el);
                }
              );

          });
        }
      );
  }

  public onRowSelect(evt): void {
    this.allClassBooks[evt.index].stato = Status.ATTESA;
  }

  public onRowUnselect(evt): void {
    this.allClassBooks[evt.index].stato = Status.NON_ORDINATO;
  }

  public calculateBookingCost() {
    let tot = 0;
    this.toBeBooked.forEach((e) => {
      tot += e.libri.prezzo;
    });
    return tot.toFixed(2);
  }

  public claculanteToBePaied() {
    let tot: number = Number.parseFloat(this.calculateBookingCost());
    tot -= this.bookingInfo.caparra;
    return tot.toFixed(2);
  }


}
